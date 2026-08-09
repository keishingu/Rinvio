import Foundation

public enum ModifierKey: String, Codable, Hashable, Sendable {
  case command
  case shift
  case control
  case option
}

public struct KeyStroke: Codable, Equatable, Hashable, Sendable {
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

public enum MeetingAction: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
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
    ActionCatalog.defaultTrigger(for: self).displayValue
  }
}

public enum ActionTarget: String, CaseIterable, Codable, Equatable, Sendable {
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

public enum ActionCatalog {
  public static func defaultTrigger(for action: MeetingAction) -> KeyStroke {
    switch action {
    case .mute:
      KeyStroke(virtualKeyCode: 97, modifiers: [], displayValue: "F6")
    case .camera:
      KeyStroke(virtualKeyCode: 98, modifiers: [], displayValue: "F7")
    case .raiseHand:
      KeyStroke(virtualKeyCode: 100, modifiers: [], displayValue: "F8")
    }
  }

  public static func defaultShortcut(
    for action: MeetingAction,
    target: ActionTarget
  ) -> KeyStroke {
    switch (target, action) {
    case (.microsoftTeams, .mute):
      KeyStroke(virtualKeyCode: 46, modifiers: [.command, .shift], displayValue: "⌘⇧M")
    case (.microsoftTeams, .camera):
      KeyStroke(virtualKeyCode: 31, modifiers: [.command, .shift], displayValue: "⌘⇧O")
    case (.microsoftTeams, .raiseHand):
      KeyStroke(virtualKeyCode: 40, modifiers: [.command, .shift], displayValue: "⌘⇧K")
    case (.zoomWorkplace, .mute):
      KeyStroke(virtualKeyCode: 0, modifiers: [.command, .shift], displayValue: "⌘⇧A")
    case (.zoomWorkplace, .camera):
      KeyStroke(virtualKeyCode: 9, modifiers: [.command, .shift], displayValue: "⌘⇧V")
    case (.zoomWorkplace, .raiseHand):
      KeyStroke(virtualKeyCode: 16, modifiers: [.option], displayValue: "⌥Y")
    case (.googleMeet, .mute):
      KeyStroke(virtualKeyCode: 2, modifiers: [.command], displayValue: "⌘D")
    case (.googleMeet, .camera):
      KeyStroke(virtualKeyCode: 14, modifiers: [.command], displayValue: "⌘E")
    case (.googleMeet, .raiseHand):
      KeyStroke(virtualKeyCode: 4, modifiers: [.command, .control], displayValue: "⌃⌘H")
    }
  }
}

public protocol ShortcutOverrideProviding {
  func shortcutOverride(for action: MeetingAction, target: ActionTarget) -> KeyStroke?
}

public struct NoShortcutOverrides: ShortcutOverrideProviding, Sendable {
  public init() {}

  public func shortcutOverride(for action: MeetingAction, target: ActionTarget) -> KeyStroke? {
    nil
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

public struct ActionRouter {
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

  private let overrideProvider: any ShortcutOverrideProviding

  public init(overrideProvider: any ShortcutOverrideProviding = NoShortcutOverrides()) {
    self.overrideProvider = overrideProvider
  }

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
    overrideProvider.shortcutOverride(for: action, target: target)
      ?? ActionCatalog.defaultShortcut(for: action, target: target)
  }
}
