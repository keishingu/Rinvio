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
  case openChat
  case showParticipants
  case toggleCaptions
  case shareScreen
  case switchCamera
  case pictureInPicture
  case reactionLike
  case reactionHeart
  case reactionClap
  case reactionLaugh
  case reactionWow
  case reactionCelebrate

  public var id: Self { self }

  public var displayName: String {
    switch self {
    case .mute: "Mute"
    case .camera: "Camera"
    case .raiseHand: "Raise Hand"
    case .openChat: "Open Chat"
    case .showParticipants: "Show Participants"
    case .toggleCaptions: "Captions"
    case .shareScreen: "Share Screen"
    case .switchCamera: "Switch Camera"
    case .pictureInPicture: "Picture in Picture"
    case .reactionLike: "Thumbs Up"
    case .reactionHeart: "Heart"
    case .reactionClap: "Clap"
    case .reactionLaugh: "Laugh"
    case .reactionWow: "Wow"
    case .reactionCelebrate: "Celebrate"
    }
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
  public static func defaultTrigger(for action: MeetingAction) -> KeyStroke? {
    switch action {
    case .mute:
      KeyStroke(virtualKeyCode: 97, modifiers: [], displayValue: "F6")
    case .camera:
      KeyStroke(virtualKeyCode: 98, modifiers: [], displayValue: "F7")
    case .raiseHand:
      KeyStroke(virtualKeyCode: 100, modifiers: [], displayValue: "F8")
    case .openChat, .showParticipants, .toggleCaptions, .shareScreen, .switchCamera,
      .pictureInPicture, .reactionLike, .reactionHeart, .reactionClap, .reactionLaugh,
      .reactionWow, .reactionCelebrate:
      nil
    }
  }

  public static func defaultShortcut(
    for action: MeetingAction,
    target: ActionTarget
  ) -> KeyStroke? {
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
    case (.zoomWorkplace, .openChat):
      KeyStroke(virtualKeyCode: 4, modifiers: [.command, .shift], displayValue: "⌘⇧H")
    case (.googleMeet, .openChat):
      KeyStroke(virtualKeyCode: 8, modifiers: [.command, .control], displayValue: "⌃⌘C")
    case (.zoomWorkplace, .showParticipants):
      KeyStroke(virtualKeyCode: 32, modifiers: [.command], displayValue: "⌘U")
    case (.googleMeet, .showParticipants):
      KeyStroke(virtualKeyCode: 35, modifiers: [.command, .control], displayValue: "⌃⌘P")
    case (.microsoftTeams, .toggleCaptions):
      KeyStroke(virtualKeyCode: 0, modifiers: [.command, .shift], displayValue: "⌘⇧A")
    case (.googleMeet, .toggleCaptions):
      KeyStroke(virtualKeyCode: 8, modifiers: [], displayValue: "C")
    case (.microsoftTeams, .shareScreen):
      KeyStroke(virtualKeyCode: 14, modifiers: [.command, .shift], displayValue: "⌘⇧E")
    case (.zoomWorkplace, .shareScreen):
      KeyStroke(virtualKeyCode: 1, modifiers: [.command, .shift], displayValue: "⌘⇧S")
    case (.googleMeet, .shareScreen):
      KeyStroke(virtualKeyCode: 17, modifiers: [.command, .control], displayValue: "⌃⌘T")
    case (.zoomWorkplace, .switchCamera):
      KeyStroke(virtualKeyCode: 45, modifiers: [.command, .shift], displayValue: "⌘⇧N")
    case (.googleMeet, .pictureInPicture):
      KeyStroke(virtualKeyCode: 46, modifiers: [.shift], displayValue: "⇧M")
    case (.zoomWorkplace, .reactionLike):
      KeyStroke(virtualKeyCode: 23, modifiers: [.command, .option], displayValue: "⌥⌘5")
    case (.zoomWorkplace, .reactionHeart):
      KeyStroke(virtualKeyCode: 22, modifiers: [.command, .option], displayValue: "⌥⌘6")
    case (.zoomWorkplace, .reactionClap):
      KeyStroke(virtualKeyCode: 21, modifiers: [.command, .option], displayValue: "⌥⌘4")
    case (.zoomWorkplace, .reactionLaugh):
      KeyStroke(virtualKeyCode: 26, modifiers: [.command, .option], displayValue: "⌥⌘7")
    case (.zoomWorkplace, .reactionWow):
      KeyStroke(virtualKeyCode: 28, modifiers: [.command, .option], displayValue: "⌥⌘8")
    case (.zoomWorkplace, .reactionCelebrate):
      KeyStroke(virtualKeyCode: 25, modifiers: [.command, .option], displayValue: "⌥⌘9")
    default:
      nil
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
  case unsupportedAction(action: MeetingAction, target: ActionTarget)

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
    case .unsupportedAction(let action, let target):
      "\(action.displayName) has no shortcut for \(target.displayName)"
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

    let target: ActionTarget
    if Self.teamsBundleIdentifiers.contains(bundleIdentifier) {
      target = .microsoftTeams
    } else if Self.zoomBundleIdentifiers.contains(bundleIdentifier) {
      target = .zoomWorkplace
    } else if Self.chromeBundleIdentifiers.contains(bundleIdentifier) {
      guard let activeTabURL = context.activeTabURL else {
        return .failure(.browserContextUnavailable)
      }

      let scheme = activeTabURL.scheme?.lowercased()
      let host = activeTabURL.host?.lowercased()
      guard scheme == "https", host == "meet.google.com" else {
        return .failure(.unsupportedWebPage(host: host))
      }
      target = .googleMeet
    } else {
      return .failure(.unsupportedApplication(bundleIdentifier: bundleIdentifier))
    }

    guard let shortcut = shortcut(for: action, target: target) else {
      return .failure(.unsupportedAction(action: action, target: target))
    }
    return .success(ActionRoute(action: action, target: target, shortcut: shortcut))
  }

  public func shortcut(for action: MeetingAction, target: ActionTarget) -> KeyStroke? {
    overrideProvider.shortcutOverride(for: action, target: target)
      ?? ActionCatalog.defaultShortcut(for: action, target: target)
  }
}
