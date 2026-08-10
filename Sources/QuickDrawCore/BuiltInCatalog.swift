import Foundation

public enum CatalogExecutionMethod: String, Codable, Sendable {
  case keyboardShortcut
}

public struct CatalogWebApplication: Codable, Equatable, Sendable {
  public let browserTarget: ActionTarget
  public let scheme: String
  public let host: String
}

public struct CatalogApplication: Codable, Equatable, Sendable {
  public let target: ActionTarget
  public let domains: [ActionDomain]
  public let bundleIdentifiers: [String]
  public let webApplication: CatalogWebApplication?
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
    mappings.first { $0.action == action && $0.target == target }?.execution.shortcut
  }

  public func application(for target: ActionTarget) -> CatalogApplication {
    applications.first { $0.target == target }!
  }

  public func triggerScopesOverlap(_ first: ActionDomain, _ second: ActionDomain) -> Bool {
    first == second
      || applications.contains { application in
        application.domains.contains(first) && application.domains.contains(second)
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
      guard let webApplication = application.webApplication else { continue }
      guard
        webApplication.browserTarget != application.target,
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

  public static func requiresWebApplicationDetection(
    bundleIdentifier: String,
    domain: ActionDomain
  ) -> Bool {
    guard let target = target(forBundleIdentifier: bundleIdentifier) else { return false }
    return webApplication(in: target, domain: domain) != nil
  }
}
