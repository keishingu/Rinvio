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

public enum MuteExecutionMode: String, Equatable, Sendable {
  case live
  case dryRun
}

public enum BrowserClassification: String, Equatable, Sendable {
  case googleMeet
  case other
  case unavailable

  public var displayName: String {
    switch self {
    case .googleMeet:
      return "Google Meet"
    case .other:
      return "Other web page"
    case .unavailable:
      return "Unavailable"
    }
  }
}

public enum MutePipelineFailure: Error, Equatable, Sendable {
  case noForegroundApplication
  case browserContextUnavailable(message: String)
  case routing(MuteRoutingFailure)
  case targetChanged
  case shortcutDeliveryFailed(message: String)

  public var userMessage: String {
    switch self {
    case .noForegroundApplication:
      return "No foreground application"
    case .browserContextUnavailable(let message):
      return message
    case .routing(let failure):
      return failure.userMessage
    case .targetChanged:
      return "Target changed before shortcut delivery"
    case .shortcutDeliveryFailed(let message):
      return message
    }
  }
}

public enum MutePipelineOutcome: Equatable, Sendable {
  case delivered(MuteRoute)
  case dryRun(MuteRoute)
  case failed(MutePipelineFailure)

  public var route: MuteRoute? {
    switch self {
    case .delivered(let route), .dryRun(let route):
      return route
    case .failed:
      return nil
    }
  }
}

public struct MutePipelineReport: Equatable, Sendable {
  public let mode: MuteExecutionMode
  public let application: ApplicationSnapshot?
  public let browserClassification: BrowserClassification?
  public let outcome: MutePipelineOutcome
  public let latencyNanoseconds: UInt64

  public init(
    mode: MuteExecutionMode,
    application: ApplicationSnapshot?,
    browserClassification: BrowserClassification?,
    outcome: MutePipelineOutcome,
    latencyNanoseconds: UInt64
  ) {
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

public final class MutePipeline {
  private let router: MuteRouter
  private let applicationProvider: any ForegroundApplicationProviding
  private let activeTabProvider: any ActiveTabURLProviding
  private let shortcutDeliverer: any ShortcutDelivering
  private let uptimeProvider: any UptimeProviding

  public init(
    router: MuteRouter = MuteRouter(),
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

  public func run(mode: MuteExecutionMode) -> MutePipelineReport {
    let startedAt = uptimeProvider.nowNanoseconds()

    guard let application = applicationProvider.foregroundApplication() else {
      return report(
        startedAt: startedAt,
        mode: mode,
        application: nil,
        browserClassification: nil,
        outcome: .failed(.noForegroundApplication)
      )
    }

    let bundleIdentifier = application.bundleIdentifier
    var activeTabURL: URL?
    var browserClassification: BrowserClassification?

    if bundleIdentifier.map(MuteRouter.chromeBundleIdentifiers.contains) == true {
      do {
        activeTabURL = try activeTabProvider.activeTabURL()
        browserClassification = Self.classifyBrowserURL(activeTabURL)
      } catch {
        return report(
          startedAt: startedAt,
          mode: mode,
          application: application,
          browserClassification: .unavailable,
          outcome: .failed(
            .browserContextUnavailable(message: error.localizedDescription)
          )
        )
      }
    }

    let context = ForegroundContext(
      bundleIdentifier: bundleIdentifier,
      activeTabURL: activeTabURL
    )

    switch router.route(context) {
    case .failure(let failure):
      return report(
        startedAt: startedAt,
        mode: mode,
        application: application,
        browserClassification: browserClassification,
        outcome: .failed(.routing(failure))
      )

    case .success(let route):
      if mode == .dryRun {
        return report(
          startedAt: startedAt,
          mode: mode,
          application: application,
          browserClassification: browserClassification,
          outcome: .dryRun(route)
        )
      }

      guard applicationProvider.isStillForeground(application) else {
        return report(
          startedAt: startedAt,
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
          mode: mode,
          application: application,
          browserClassification: browserClassification,
          outcome: .delivered(route)
        )
      } catch {
        return report(
          startedAt: startedAt,
          mode: mode,
          application: application,
          browserClassification: browserClassification,
          outcome: .failed(
            .shortcutDeliveryFailed(message: error.localizedDescription)
          )
        )
      }
    }
  }

  private static func classifyBrowserURL(_ url: URL?) -> BrowserClassification {
    guard let url else {
      return .unavailable
    }
    return url.scheme?.lowercased() == "https"
      && url.host?.lowercased() == "meet.google.com"
      ? .googleMeet
      : .other
  }

  private func report(
    startedAt: UInt64,
    mode: MuteExecutionMode,
    application: ApplicationSnapshot?,
    browserClassification: BrowserClassification?,
    outcome: MutePipelineOutcome
  ) -> MutePipelineReport {
    let finishedAt = uptimeProvider.nowNanoseconds()
    return MutePipelineReport(
      mode: mode,
      application: application,
      browserClassification: browserClassification,
      outcome: outcome,
      latencyNanoseconds: finishedAt >= startedAt ? finishedAt - startedAt : 0
    )
  }
}
