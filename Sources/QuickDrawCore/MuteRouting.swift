import Foundation

public enum ModifierKey: String, Hashable, Sendable {
  case command
  case shift
  case control
  case option
}

public struct KeyStroke: Equatable, Sendable {
  public let virtualKeyCode: UInt16
  public let modifiers: Set<ModifierKey>
  public let displayValue: String

  public init(
    virtualKeyCode: UInt16,
    modifiers: Set<ModifierKey>,
    displayValue: String
  ) {
    self.virtualKeyCode = virtualKeyCode
    self.modifiers = modifiers
    self.displayValue = displayValue
  }
}

public enum MuteTarget: String, Equatable, Sendable {
  case microsoftTeams
  case zoomWorkplace
  case googleMeet

  public var displayName: String {
    switch self {
    case .microsoftTeams:
      return "Microsoft Teams"
    case .zoomWorkplace:
      return "Zoom Workplace"
    case .googleMeet:
      return "Google Meet"
    }
  }
}

public struct MuteRoute: Equatable, Sendable {
  public let target: MuteTarget
  public let shortcut: KeyStroke

  public init(target: MuteTarget, shortcut: KeyStroke) {
    self.target = target
    self.shortcut = shortcut
  }
}

public struct ForegroundContext: Equatable, Sendable {
  public let bundleIdentifier: String?
  public let activeTabURL: URL?

  public init(bundleIdentifier: String?, activeTabURL: URL? = nil) {
    self.bundleIdentifier = bundleIdentifier
    self.activeTabURL = activeTabURL
  }
}

public enum MuteRoutingFailure: Error, Equatable, Sendable {
  case missingBundleIdentifier
  case browserContextUnavailable
  case unsupportedWebPage(host: String?)
  case unsupportedApplication(bundleIdentifier: String)

  public var userMessage: String {
    switch self {
    case .missingBundleIdentifier:
      return "Foreground application could not be identified"
    case .browserContextUnavailable:
      return "Chrome active tab could not be read"
    case .unsupportedWebPage:
      return "Active Chrome tab is not Google Meet"
    case .unsupportedApplication(let bundleIdentifier):
      return "Unsupported foreground application (\(bundleIdentifier))"
    }
  }
}

public struct MuteRouter: Sendable {
  public static let teamsBundleIdentifiers: Set<String> = [
    "com.microsoft.teams2",
    "com.microsoft.teams",
  ]

  public static let zoomBundleIdentifiers: Set<String> = [
    "us.zoom.xos"
  ]

  public static let chromeBundleIdentifiers: Set<String> = [
    "com.google.Chrome"
  ]

  public init() {}

  public func route(_ context: ForegroundContext) -> Result<MuteRoute, MuteRoutingFailure> {
    guard let bundleIdentifier = context.bundleIdentifier else {
      return .failure(.missingBundleIdentifier)
    }

    if Self.teamsBundleIdentifiers.contains(bundleIdentifier) {
      return .success(
        MuteRoute(
          target: .microsoftTeams,
          shortcut: KeyStroke(
            virtualKeyCode: 46,  // kVK_ANSI_M
            modifiers: [.command, .shift],
            displayValue: "⌘⇧M"
          )
        )
      )
    }

    if Self.zoomBundleIdentifiers.contains(bundleIdentifier) {
      return .success(
        MuteRoute(
          target: .zoomWorkplace,
          shortcut: KeyStroke(
            virtualKeyCode: 0,  // kVK_ANSI_A
            modifiers: [.command, .shift],
            displayValue: "⌘⇧A"
          )
        )
      )
    }

    if Self.chromeBundleIdentifiers.contains(bundleIdentifier) {
      guard let activeTabURL = context.activeTabURL else {
        return .failure(.browserContextUnavailable)
      }

      let scheme = activeTabURL.scheme?.lowercased()
      let host = activeTabURL.host?.lowercased()
      guard scheme == "https", host == "meet.google.com" else {
        return .failure(.unsupportedWebPage(host: host))
      }

      return .success(
        MuteRoute(
          target: .googleMeet,
          shortcut: KeyStroke(
            virtualKeyCode: 2,  // kVK_ANSI_D
            modifiers: [.command],
            displayValue: "⌘D"
          )
        )
      )
    }

    return .failure(.unsupportedApplication(bundleIdentifier: bundleIdentifier))
  }
}
