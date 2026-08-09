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

public enum MeetingAction: String, CaseIterable, Equatable, Identifiable, Sendable {
  case mute
  case camera
  case raiseHand

  public var id: Self { self }

  public var displayName: String {
    switch self {
    case .mute: "Mute"
    case .camera: "Camera"
    case .raiseHand: "Raise Hand"
    }
  }

  public var triggerDisplayValue: String {
    switch self {
    case .mute: "F6"
    case .camera: "F7"
    case .raiseHand: "F8"
    }
  }
}

public enum ActionTarget: String, Equatable, Sendable {
  case microsoftTeams
  case zoomWorkplace
  case googleMeet

  public var displayName: String {
    switch self {
    case .microsoftTeams: "Microsoft Teams"
    case .zoomWorkplace: "Zoom Workplace"
    case .googleMeet: "Google Meet"
    }
  }
}

public struct ActionRoute: Equatable, Sendable {
  public let action: MeetingAction
  public let target: ActionTarget
  public let shortcut: KeyStroke

  public init(action: MeetingAction, target: ActionTarget, shortcut: KeyStroke) {
    self.action = action
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

public enum ActionRoutingFailure: Error, Equatable, Sendable {
  case missingBundleIdentifier
  case browserContextUnavailable
  case unsupportedWebPage(host: String?)
  case unsupportedApplication(bundleIdentifier: String)

  public var userMessage: String {
    switch self {
    case .missingBundleIdentifier:
      "Foreground application could not be identified"
    case .browserContextUnavailable:
      "Chrome active tab could not be read"
    case .unsupportedWebPage:
      "Active Chrome tab is not Google Meet"
    case .unsupportedApplication(let bundleIdentifier):
      "Unsupported foreground application (\(bundleIdentifier))"
    }
  }
}

public struct ActionRouter: Sendable {
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

  public func route(
    action: MeetingAction,
    context: ForegroundContext
  ) -> Result<ActionRoute, ActionRoutingFailure> {
    guard let bundleIdentifier = context.bundleIdentifier else {
      return .failure(.missingBundleIdentifier)
    }

    if Self.teamsBundleIdentifiers.contains(bundleIdentifier) {
      return .success(
        ActionRoute(
          action: action,
          target: .microsoftTeams,
          shortcut: shortcut(for: action, target: .microsoftTeams)
        )
      )
    }

    if Self.zoomBundleIdentifiers.contains(bundleIdentifier) {
      return .success(
        ActionRoute(
          action: action,
          target: .zoomWorkplace,
          shortcut: shortcut(for: action, target: .zoomWorkplace)
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
        ActionRoute(
          action: action,
          target: .googleMeet,
          shortcut: shortcut(for: action, target: .googleMeet)
        )
      )
    }

    return .failure(.unsupportedApplication(bundleIdentifier: bundleIdentifier))
  }

  public func shortcut(for action: MeetingAction, target: ActionTarget) -> KeyStroke {
    switch target {
    case .microsoftTeams: teamsShortcut(for: action)
    case .zoomWorkplace: zoomShortcut(for: action)
    case .googleMeet: meetShortcut(for: action)
    }
  }

  private func teamsShortcut(for action: MeetingAction) -> KeyStroke {
    switch action {
    case .mute:
      KeyStroke(virtualKeyCode: 46, modifiers: [.command, .shift], displayValue: "⌘⇧M")
    case .camera:
      KeyStroke(virtualKeyCode: 31, modifiers: [.command, .shift], displayValue: "⌘⇧O")
    case .raiseHand:
      KeyStroke(virtualKeyCode: 40, modifiers: [.command, .shift], displayValue: "⌘⇧K")
    }
  }

  private func zoomShortcut(for action: MeetingAction) -> KeyStroke {
    switch action {
    case .mute:
      KeyStroke(virtualKeyCode: 0, modifiers: [.command, .shift], displayValue: "⌘⇧A")
    case .camera:
      KeyStroke(virtualKeyCode: 9, modifiers: [.command, .shift], displayValue: "⌘⇧V")
    case .raiseHand:
      KeyStroke(virtualKeyCode: 16, modifiers: [.option], displayValue: "⌥Y")
    }
  }

  private func meetShortcut(for action: MeetingAction) -> KeyStroke {
    switch action {
    case .mute:
      KeyStroke(virtualKeyCode: 2, modifiers: [.command], displayValue: "⌘D")
    case .camera:
      KeyStroke(virtualKeyCode: 14, modifiers: [.command], displayValue: "⌘E")
    case .raiseHand:
      KeyStroke(virtualKeyCode: 4, modifiers: [.command, .control], displayValue: "⌃⌘H")
    }
  }
}
