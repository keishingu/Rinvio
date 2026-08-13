import Foundation

public enum CatalogExecutionMethod: String, Codable, Sendable {
  case keyboardShortcut
}

public struct CatalogWebApplication: Codable, Equatable, Sendable {
  public let browserTarget: ActionTarget
  public let scheme: String
  public let hosts: [String]

  public var host: String { hosts[0] }

  private enum CodingKeys: String, CodingKey {
    case browserTarget
    case scheme
    case host
    case hosts
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    browserTarget = try container.decode(ActionTarget.self, forKey: .browserTarget)
    scheme = try container.decode(String.self, forKey: .scheme)
    if let hosts = try container.decodeIfPresent([String].self, forKey: .hosts) {
      self.hosts = hosts
    } else {
      self.hosts = [try container.decode(String.self, forKey: .host)]
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(browserTarget, forKey: .browserTarget)
    try container.encode(scheme, forKey: .scheme)
    try container.encode(hosts, forKey: .hosts)
  }

  public func matches(_ url: URL) -> Bool {
    url.scheme?.lowercased() == scheme.lowercased()
      && hosts.contains { $0.lowercased() == url.host?.lowercased() }
  }
}

public struct CatalogApplication: Codable, Equatable, Sendable {
  public let target: ActionTarget
  public let domains: [ActionDomain]
  public let bundleIdentifiers: [String]
  public let inheritsMappingsFrom: ActionTarget?
  public let webApplication: CatalogWebApplication?
  public let officialURL: URL?
}

public struct CatalogExecution: Codable, Equatable, Sendable {
  public let method: CatalogExecutionMethod
  public let shortcut: KeyStroke
}

public struct CatalogMapping: Codable, Equatable, Sendable {
  public let action: Action
  public let target: ActionTarget
  public let execution: CatalogExecution
}

public enum BuiltInCatalogError: Error, Equatable {
  case unsupportedSchemaVersion(Int)
  case duplicateAction(Action)
  case incompleteActions
  case duplicateApplication(ActionTarget)
  case incompleteApplications
  case duplicateBundleIdentifier(String)
  case duplicateMapping(Action, ActionTarget)
  case domainMismatch(Action, ActionTarget)
  case invalidMappingInheritance(ActionTarget)
  case duplicateTrigger(Action, Action)
  case invalidWebApplication(ActionTarget)
}

public struct BuiltInCatalog: Sendable {
  public static let currentSchemaVersion = 2

  private struct Document: Decodable {
    let schemaVersion: Int
    let actions: [CatalogAction]
    let applications: [CatalogApplication]
    let mappings: [CatalogMapping]
  }

  private struct CatalogAction: Codable, Equatable, Sendable {
    let action: Action
    let domain: ActionDomain
    let defaultTrigger: KeyStroke
  }

  private let actions: [CatalogAction]
  public let applications: [CatalogApplication]
  public let mappings: [CatalogMapping]

  public init(data: Data) throws {
    let document = try JSONDecoder().decode(Document.self, from: data)
    guard document.schemaVersion == Self.currentSchemaVersion else {
      throw BuiltInCatalogError.unsupportedSchemaVersion(document.schemaVersion)
    }
    try Self.validate(document)
    actions = document.actions
    applications = document.applications
    mappings = document.mappings
  }

  public func domain(for action: Action) -> ActionDomain {
    actions.first { $0.action == action }!.domain
  }

  public func defaultTrigger(for action: Action) -> KeyStroke {
    actions.first { $0.action == action }!.defaultTrigger
  }

  public func defaultShortcut(for action: Action, target: ActionTarget) -> KeyStroke? {
    if let shortcut = mappings.first(where: { $0.action == action && $0.target == target })?
      .execution.shortcut
    {
      return shortcut
    }
    guard let inheritedTarget = application(for: target).inheritsMappingsFrom else { return nil }
    return mappings.first { $0.action == action && $0.target == inheritedTarget }?.execution
      .shortcut
  }

  public func application(for target: ActionTarget) -> CatalogApplication {
    applications.first { $0.target == target }!
  }

  public func triggerScopesOverlap(_ first: ActionDomain, _ second: ActionDomain) -> Bool {
    if first == .system || second == .system {
      return first == second
    }
    return first == second
      || applications.contains { application in
        application.domains.contains(first) && application.domains.contains(second)
      }
      || webDomain(first, overlapsBrowserDomain: second)
      || webDomain(second, overlapsBrowserDomain: first)
  }

  private func webDomain(
    _ webDomain: ActionDomain,
    overlapsBrowserDomain browserDomain: ActionDomain
  ) -> Bool {
    applications.contains { application in
      guard
        application.domains.contains(webDomain),
        let browserTarget = application.webApplication?.browserTarget
      else { return false }
      return self.application(for: browserTarget).domains.contains(browserDomain)
    }
  }

  public func target(forBundleIdentifier bundleIdentifier: String) -> ActionTarget? {
    applications.first { $0.bundleIdentifiers.contains(bundleIdentifier) }?.target
  }

  public func webApplication(
    in browserTarget: ActionTarget,
    domain: ActionDomain
  ) -> CatalogApplication? {
    applications.first {
      $0.domains.contains(domain) && $0.webApplication?.browserTarget == browserTarget
    }
  }

  public func webApplication(
    in browserTarget: ActionTarget,
    matching url: URL
  ) -> CatalogApplication? {
    applications.first {
      $0.webApplication?.browserTarget == browserTarget
        && $0.webApplication?.matches(url) == true
    }
  }

  public func isSystemWide(_ action: Action) -> Bool {
    domain(for: action) == .system
  }

  private static func validate(_ document: Document) throws {
    var seenActions: Set<Action> = []
    for item in document.actions {
      guard seenActions.insert(item.action).inserted else {
        throw BuiltInCatalogError.duplicateAction(item.action)
      }
    }
    guard seenActions == Set(Action.allCases) else {
      throw BuiltInCatalogError.incompleteActions
    }

    var seenApplications: Set<ActionTarget> = []
    var seenBundleIdentifiers: Set<String> = []
    for application in document.applications {
      guard seenApplications.insert(application.target).inserted else {
        throw BuiltInCatalogError.duplicateApplication(application.target)
      }
      guard !application.domains.isEmpty else {
        throw BuiltInCatalogError.incompleteApplications
      }
      for bundleIdentifier in application.bundleIdentifiers {
        guard seenBundleIdentifiers.insert(bundleIdentifier).inserted else {
          throw BuiltInCatalogError.duplicateBundleIdentifier(bundleIdentifier)
        }
      }
    }
    guard seenApplications == Set(ActionTarget.allCases) else {
      throw BuiltInCatalogError.incompleteApplications
    }

    for application in document.applications {
      guard let inheritedTarget = application.inheritsMappingsFrom else { continue }
      guard
        inheritedTarget != application.target,
        let inheritedApplication = document.applications.first(where: {
          $0.target == inheritedTarget
        }),
        application.domains.allSatisfy(inheritedApplication.domains.contains),
        inheritedApplication.inheritsMappingsFrom == nil
      else {
        throw BuiltInCatalogError.invalidMappingInheritance(application.target)
      }
    }

    for application in document.applications {
      guard let webApplication = application.webApplication else { continue }
      guard
        webApplication.browserTarget != application.target,
        !webApplication.scheme.isEmpty,
        !webApplication.hosts.isEmpty,
        webApplication.hosts.allSatisfy({ !$0.isEmpty }),
        document.applications.contains(where: {
          $0.target == webApplication.browserTarget && !$0.bundleIdentifiers.isEmpty
        })
      else {
        throw BuiltInCatalogError.invalidWebApplication(application.target)
      }
    }

    var seenMappings: Set<String> = []
    for mapping in document.mappings {
      let key = "\(mapping.action.rawValue):\(mapping.target.rawValue)"
      guard seenMappings.insert(key).inserted else {
        throw BuiltInCatalogError.duplicateMapping(mapping.action, mapping.target)
      }
      guard
        let actionDomain = document.actions.first(where: { $0.action == mapping.action })?.domain,
        let application = document.applications.first(where: { $0.target == mapping.target }),
        application.domains.contains(actionDomain)
      else {
        throw BuiltInCatalogError.domainMismatch(mapping.action, mapping.target)
      }
    }

    for (index, action) in document.actions.enumerated() {
      if let duplicate = document.actions.dropFirst(index + 1).first(where: { candidate in
        let scopesOverlap =
          candidate.domain == action.domain
          || document.applications.contains { application in
            application.domains.contains(action.domain)
              && application.domains.contains(candidate.domain)
          }
        return scopesOverlap
          && candidate.defaultTrigger.matchesPhysicalShortcut(action.defaultTrigger)
      }) {
        throw BuiltInCatalogError.duplicateTrigger(action.action, duplicate.action)
      }
    }
  }
}

public enum ActionCatalog {
  private static let builtIn: BuiltInCatalog = {
    let url =
      Bundle.main.url(forResource: "built-in-catalog", withExtension: "json")
      ?? Bundle.module.url(forResource: "built-in-catalog", withExtension: "json")
    guard let url else {
      fatalError("Built-in QuickDraw catalog is missing")
    }
    do {
      return try BuiltInCatalog(data: Data(contentsOf: url))
    } catch {
      fatalError("Built-in QuickDraw catalog is invalid: \(error)")
    }
  }()

  public static func domain(for action: Action) -> ActionDomain {
    builtIn.domain(for: action)
  }

  public static func defaultTrigger(for action: Action) -> KeyStroke? {
    builtIn.defaultTrigger(for: action)
  }

  public static func defaultShortcut(
    for action: Action,
    target: ActionTarget
  ) -> KeyStroke? {
    builtIn.defaultShortcut(for: action, target: target)
  }

  public static func application(for target: ActionTarget) -> CatalogApplication {
    builtIn.application(for: target)
  }

  public static func target(forBundleIdentifier bundleIdentifier: String) -> ActionTarget? {
    builtIn.target(forBundleIdentifier: bundleIdentifier)
  }

  public static func triggerScopesOverlap(_ first: Action, _ second: Action) -> Bool {
    builtIn.triggerScopesOverlap(first.domain, second.domain)
  }

  public static func webApplication(
    in browserTarget: ActionTarget,
    domain: ActionDomain
  ) -> CatalogApplication? {
    builtIn.webApplication(in: browserTarget, domain: domain)
  }

  public static func webApplication(
    in browserTarget: ActionTarget,
    matching url: URL
  ) -> CatalogApplication? {
    builtIn.webApplication(in: browserTarget, matching: url)
  }

  public static func requiresWebApplicationDetection(
    bundleIdentifier: String,
    domain: ActionDomain
  ) -> Bool {
    guard let target = target(forBundleIdentifier: bundleIdentifier) else { return false }
    return webApplication(in: target, domain: domain) != nil
  }

  public static func isSystemWide(_ action: Action) -> Bool {
    builtIn.isSystemWide(action)
  }
}
