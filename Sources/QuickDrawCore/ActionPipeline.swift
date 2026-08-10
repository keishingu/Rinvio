import Dispatch
import Foundation

public struct ApplicationSnapshot: Equatable, Sendable {
  public let processIdentifier: Int32
  public let bundleIdentifier: String?

  public init(processIdentifier: Int32, bundleIdentifier: String?) {
    self.processIdentifier = processIdentifier
    self.bundleIdentifier = bundleIdentifier
  }
}

public protocol ForegroundApplicationProviding {
  func foregroundApplication() -> ApplicationSnapshot?
  func isStillForeground(_ application: ApplicationSnapshot) -> Bool
}

public protocol ActiveTabURLProviding {
  func activeTabURL() throws -> URL
}

public protocol ShortcutDelivering {
  func deliver(_ shortcut: KeyStroke) throws
}

public protocol UptimeProviding {
  func nowNanoseconds() -> UInt64
}

public struct SystemUptimeProvider: UptimeProviding, Sendable {
  public init() {}

  public func nowNanoseconds() -> UInt64 {
    DispatchTime.now().uptimeNanoseconds
  }
}

public enum ActionExecutionMode: String, Equatable, Sendable {
  case live
  case dryRun
}

public enum BrowserClassification: String, Equatable, Sendable {
  case googleMeet
  case other
  case unavailable

  public var displayName: String {
    switch self {
    case .googleMeet: "Google Meet"
    case .other: "Other web page"
    case .unavailable: "Unavailable"
    }
  }
}

public enum ActionPipelineFailure: Error, Equatable, Sendable {
  case noForegroundApplication
  case browserContextUnavailable(message: String)
  case routing(ActionRoutingFailure)
  case targetChanged
  case shortcutDeliveryFailed(message: String)

  public var userMessage: String {
    switch self {
    case .noForegroundApplication:
      "No foreground application"
    case .browserContextUnavailable(let message):
      message
    case .routing(let failure):
      failure.userMessage
    case .targetChanged:
      "Target changed before shortcut delivery"
    case .shortcutDeliveryFailed(let message):
      message
    }
  }
}

public enum ActionPipelineOutcome: Equatable, Sendable {
  case delivered(ActionRoute)
  case dryRun(ActionRoute)
  case failed(ActionPipelineFailure)

  public var route: ActionRoute? {
    switch self {
    case .delivered(let route), .dryRun(let route): route
    case .failed: nil
    }
  }

  public var consumesTrigger: Bool {
    switch self {
    case .delivered, .dryRun:
      true
    case .failed(let failure):
      switch failure {
      case .noForegroundApplication, .browserContextUnavailable:
        false
      case .routing(let routingFailure):
        switch routingFailure {
        case .missingBundleIdentifier, .browserContextUnavailable, .unsupportedWebPage,
          .unsupportedApplication, .disabledApplication, .inactiveDomain, .unsupportedAction:
          false
        }
      case .targetChanged, .shortcutDeliveryFailed:
        true
      }
    }
  }
}

public struct ActionPipelineReport: Equatable, Sendable {
  public let action: Action
  public let mode: ActionExecutionMode
  public let application: ApplicationSnapshot?
  public let browserClassification: BrowserClassification?
  public let outcome: ActionPipelineOutcome
  public let latencyNanoseconds: UInt64

  public init(
    action: Action,
    mode: ActionExecutionMode,
    application: ApplicationSnapshot?,
    browserClassification: BrowserClassification?,
    outcome: ActionPipelineOutcome,
    latencyNanoseconds: UInt64
  ) {
    self.action = action
    self.mode = mode
    self.application = application
    self.browserClassification = browserClassification
    self.outcome = outcome
    self.latencyNanoseconds = latencyNanoseconds
  }

  public var latencyMilliseconds: Double {
    Double(latencyNanoseconds) / 1_000_000
  }
}

public final class ActionPipeline {
  private let router: ActionRouter
  private let applicationProvider: any ForegroundApplicationProviding
  private let activeTabProvider: any ActiveTabURLProviding
  private let shortcutDeliverer: any ShortcutDelivering
  private let uptimeProvider: any UptimeProviding

  public init(
    router: ActionRouter = ActionRouter(),
    applicationProvider: any ForegroundApplicationProviding,
    activeTabProvider: any ActiveTabURLProviding,
    shortcutDeliverer: any ShortcutDelivering,
    uptimeProvider: any UptimeProviding = SystemUptimeProvider()
  ) {
    self.router = router
    self.applicationProvider = applicationProvider
    self.activeTabProvider = activeTabProvider
    self.shortcutDeliverer = shortcutDeliverer
    self.uptimeProvider = uptimeProvider
  }

  public func run(action: Action, mode: ActionExecutionMode) -> ActionPipelineReport {
    let startedAt = uptimeProvider.nowNanoseconds()

    guard let application = applicationProvider.foregroundApplication() else {
      return report(
        startedAt: startedAt,
        action: action,
        mode: mode,
        application: nil,
        browserClassification: nil,
        outcome: .failed(.noForegroundApplication)
      )
    }

    let bundleIdentifier = application.bundleIdentifier
    var activeTabURL: URL?
    var browserClassification: BrowserClassification?

    if let bundleIdentifier,
      ActionCatalog.requiresWebApplicationDetection(
        bundleIdentifier: bundleIdentifier,
        domain: action.domain
      )
    {
      do {
        activeTabURL = try activeTabProvider.activeTabURL()
        browserClassification = Self.classifyBrowserURL(activeTabURL)
      } catch {
        return report(
          startedAt: startedAt,
          action: action,
          mode: mode,
          application: application,
          browserClassification: .unavailable,
          outcome: .failed(.browserContextUnavailable(message: error.localizedDescription))
        )
      }
    }

    let context = ForegroundContext(
      bundleIdentifier: bundleIdentifier,
      activeTabURL: activeTabURL
    )

    switch router.route(action: action, context: context) {
    case .failure(let failure):
      return report(
        startedAt: startedAt,
        action: action,
        mode: mode,
        application: application,
        browserClassification: browserClassification,
        outcome: .failed(.routing(failure))
      )

    case .success(let route):
      if mode == .dryRun {
        return report(
          startedAt: startedAt,
          action: action,
          mode: mode,
          application: application,
          browserClassification: browserClassification,
          outcome: .dryRun(route)
        )
      }

      guard applicationProvider.isStillForeground(application) else {
        return report(
          startedAt: startedAt,
          action: action,
          mode: mode,
          application: application,
          browserClassification: browserClassification,
          outcome: .failed(.targetChanged)
        )
      }

      do {
        try shortcutDeliverer.deliver(route.shortcut)
        return report(
          startedAt: startedAt,
          action: action,
          mode: mode,
          application: application,
          browserClassification: browserClassification,
          outcome: .delivered(route)
        )
      } catch {
        return report(
          startedAt: startedAt,
          action: action,
          mode: mode,
          application: application,
          browserClassification: browserClassification,
          outcome: .failed(.shortcutDeliveryFailed(message: error.localizedDescription))
        )
      }
    }
  }

  private static func classifyBrowserURL(_ url: URL?) -> BrowserClassification {
    guard let url else { return .unavailable }
    return url.scheme?.lowercased() == "https"
      && url.host?.lowercased() == "meet.google.com"
      ? .googleMeet
      : .other
  }

  private func report(
    startedAt: UInt64,
    action: Action,
    mode: ActionExecutionMode,
    application: ApplicationSnapshot?,
    browserClassification: BrowserClassification?,
    outcome: ActionPipelineOutcome
  ) -> ActionPipelineReport {
    let finishedAt = uptimeProvider.nowNanoseconds()
    return ActionPipelineReport(
      action: action,
      mode: mode,
      application: application,
      browserClassification: browserClassification,
      outcome: outcome,
      latencyNanoseconds: finishedAt >= startedAt ? finishedAt - startedAt : 0
    )
  }
}
