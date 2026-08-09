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

public enum ActionDomain: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
  case meeting
  case development
  case browser

  public var id: Self { self }
}

public enum Action: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
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
  case newSession
  case hardReload

  public var id: Self { self }

  public var domain: ActionDomain {
    switch self {
    case .newSession: .development
    case .hardReload: .browser
    default: .meeting
    }
  }

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
    case .newSession: "New Session"
    case .hardReload: "Hard Reload"
    }
  }
}

public enum ActionTarget: String, CaseIterable, Codable, Equatable, Sendable {
  case microsoftTeams
  case zoomWorkplace
  case googleMeet
  case codex
  case claude
  case safari
  case googleChrome

  public var displayName: String {
    switch self {
    case .microsoftTeams: "Microsoft Teams"
    case .zoomWorkplace: "Zoom Workplace"
    case .googleMeet: "Google Meet"
    case .codex: "Codex"
    case .claude: "Claude"
    case .safari: "Safari"
    case .googleChrome: "Google Chrome"
    }
  }
}

public enum ActionCatalog {
  public static func defaultTrigger(for action: Action) -> KeyStroke? {
    switch action {
    case .mute:
      KeyStroke(virtualKeyCode: 46, modifiers: [.command, .option], displayValue: "⌘⌥M")
    case .camera:
      KeyStroke(virtualKeyCode: 8, modifiers: [.command, .option], displayValue: "⌘⌥C")
    case .raiseHand:
      KeyStroke(virtualKeyCode: 4, modifiers: [.command, .option], displayValue: "⌘⌥H")
    case .openChat:
      KeyStroke(virtualKeyCode: 31, modifiers: [.command, .option], displayValue: "⌘⌥O")
    case .showParticipants:
      KeyStroke(virtualKeyCode: 35, modifiers: [.command, .option], displayValue: "⌘⌥P")
    case .toggleCaptions:
      KeyStroke(virtualKeyCode: 37, modifiers: [.command, .option], displayValue: "⌘⌥L")
    case .shareScreen:
      KeyStroke(virtualKeyCode: 1, modifiers: [.command, .option], displayValue: "⌘⌥S")
    case .switchCamera:
      KeyStroke(virtualKeyCode: 7, modifiers: [.command, .option], displayValue: "⌘⌥X")
    case .pictureInPicture:
      KeyStroke(virtualKeyCode: 34, modifiers: [.command, .option], displayValue: "⌘⌥I")
    case .reactionLike:
      KeyStroke(virtualKeyCode: 18, modifiers: [.command, .option], displayValue: "⌘⌥1")
    case .reactionHeart:
      KeyStroke(virtualKeyCode: 19, modifiers: [.command, .option], displayValue: "⌘⌥2")
    case .reactionClap:
      KeyStroke(virtualKeyCode: 20, modifiers: [.command, .option], displayValue: "⌘⌥3")
    case .reactionLaugh:
      KeyStroke(virtualKeyCode: 21, modifiers: [.command, .option], displayValue: "⌘⌥4")
    case .reactionWow:
      KeyStroke(virtualKeyCode: 23, modifiers: [.command, .option], displayValue: "⌘⌥5")
    case .reactionCelebrate:
      KeyStroke(virtualKeyCode: 22, modifiers: [.command, .option], displayValue: "⌘⌥6")
    case .newSession:
      KeyStroke(virtualKeyCode: 45, modifiers: [.command, .option], displayValue: "⌘⌥N")
    case .hardReload:
      KeyStroke(virtualKeyCode: 15, modifiers: [.command, .option], displayValue: "⌘⌥R")
    }
  }

  public static func defaultShortcut(
    for action: Action,
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
    case (.codex, .newSession), (.claude, .newSession):
      KeyStroke(virtualKeyCode: 45, modifiers: [.command], displayValue: "⌘N")
    case (.safari, .hardReload):
      KeyStroke(virtualKeyCode: 15, modifiers: [.command, .option], displayValue: "⌘⌥R")
    case (.googleChrome, .hardReload):
      KeyStroke(virtualKeyCode: 15, modifiers: [.command, .shift], displayValue: "⌘⇧R")
    default:
      nil
    }
  }
}

public protocol ShortcutOverrideProviding {
  func shortcutOverride(for action: Action, target: ActionTarget) -> KeyStroke?
}

public struct NoShortcutOverrides: ShortcutOverrideProviding, Sendable {
  public init() {}

  public func shortcutOverride(for action: Action, target: ActionTarget) -> KeyStroke? {
    nil
  }
}

public struct ActionRoute: Equatable, Sendable {
  public let action: Action
  public let target: ActionTarget
  public let shortcut: KeyStroke

  public init(action: Action, target: ActionTarget, shortcut: KeyStroke) {
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
  case unsupportedAction(action: Action, target: ActionTarget)

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

  public static let safariBundleIdentifiers: Set<String> = [
    "com.apple.Safari"
  ]

  public static let codexBundleIdentifiers: Set<String> = [
    "com.openai.codex"
  ]

  public static let claudeBundleIdentifiers: Set<String> = [
    "com.anthropic.claudefordesktop"
  ]

  private let overrideProvider: any ShortcutOverrideProviding

  public init(overrideProvider: any ShortcutOverrideProviding = NoShortcutOverrides()) {
    self.overrideProvider = overrideProvider
  }

  public func route(
    action: Action,
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
      if action.domain == .meeting {
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
        target = .googleChrome
      }
    } else if Self.safariBundleIdentifiers.contains(bundleIdentifier) {
      target = .safari
    } else if Self.codexBundleIdentifiers.contains(bundleIdentifier) {
      target = .codex
    } else if Self.claudeBundleIdentifiers.contains(bundleIdentifier) {
      target = .claude
    } else {
      return .failure(.unsupportedApplication(bundleIdentifier: bundleIdentifier))
    }

    guard let shortcut = shortcut(for: action, target: target) else {
      return .failure(.unsupportedAction(action: action, target: target))
    }
    return .success(ActionRoute(action: action, target: target, shortcut: shortcut))
  }

  public func shortcut(for action: Action, target: ActionTarget) -> KeyStroke? {
    overrideProvider.shortcutOverride(for: action, target: target)
      ?? ActionCatalog.defaultShortcut(for: action, target: target)
  }
}
