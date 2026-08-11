import Foundation

public enum ModifierKey: String, Codable, Hashable, Sendable {
  case command
  case shift
  case control
  case option
  case function
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
  case system
  case finder
  case meeting
  case chat
  case development
  case browser

  public var id: Self { self }
}

public enum Action: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
  case missionControl
  case applicationExpose
  case previousDesktop
  case nextDesktop
  case showDesktop
  case showNotificationCenter
  case toggleDoNotDisturb
  case toggleStageManager
  case fillWindow
  case tileWindowLeft
  case tileWindowRight
  case switchDesktop1
  case switchDesktop2
  case switchDesktop3
  case switchDesktop4
  case switchDesktop5
  case finderParentFolder
  case finderOpenSelectedItem
  case finderHome
  case finderDesktop
  case finderDownloads
  case mute
  case camera
  case raiseHand
  case openChat
  case showParticipants
  case toggleCaptions
  case shareScreen
  case switchCamera
  case pictureInPicture
  case leaveMeeting
  case reactionLike
  case reactionHeart
  case reactionClap
  case reactionLaugh
  case reactionWow
  case reactionCelebrate
  case newSession
  case toggleTerminal
  case newTerminal
  case nextTerminal
  case previousTerminal
  case splitTerminal
  case focusSidebar
  case focusMainColumn
  case focusTerminal
  case focusPreviousRegion
  case focusNextRegion
  case goToDefinition
  case goToSymbol
  case navigateBack
  case navigateForward
  case formatDocument
  case renameSymbol
  case findReferences
  case quickFix
  case toggleLineComment
  case moveLineUp
  case moveLineDown
  case runProject
  case nextIssue
  case previousIssue
  case commandPalette
  case quickOpen
  case showKeyboardShortcuts
  case hardReload
  case nextTab
  case previousTab
  case openDownloads
  case openDeveloperTools
  case reopenClosedTab
  case quickSwitcher
  case searchMessages
  case newMessage
  case previousConversation
  case nextConversation
  case openUnreads

  public var id: Self { self }

  public var domain: ActionDomain {
    ActionCatalog.domain(for: self)
  }

  public var displayName: String {
    switch self {
    case .missionControl: "Mission Control"
    case .applicationExpose: "Application Exposé"
    case .previousDesktop: "Previous Desktop"
    case .nextDesktop: "Next Desktop"
    case .showDesktop: "Show Desktop"
    case .showNotificationCenter: "Show Notification Center"
    case .toggleDoNotDisturb: "Toggle Do Not Disturb"
    case .toggleStageManager: "Toggle Stage Manager"
    case .fillWindow: "Fill Window"
    case .tileWindowLeft: "Tile Window Left"
    case .tileWindowRight: "Tile Window Right"
    case .switchDesktop1: "Switch to Desktop 1"
    case .switchDesktop2: "Switch to Desktop 2"
    case .switchDesktop3: "Switch to Desktop 3"
    case .switchDesktop4: "Switch to Desktop 4"
    case .switchDesktop5: "Switch to Desktop 5"
    case .finderParentFolder: "Parent Folder"
    case .finderOpenSelectedItem: "Open Selected Item"
    case .finderHome: "Home"
    case .finderDesktop: "Desktop"
    case .finderDownloads: "Downloads"
    case .mute: "Mute"
    case .camera: "Camera"
    case .raiseHand: "Raise Hand"
    case .openChat: "Open Chat"
    case .showParticipants: "Show Participants"
    case .toggleCaptions: "Captions"
    case .shareScreen: "Share Screen"
    case .switchCamera: "Switch Camera"
    case .pictureInPicture: "Picture in Picture"
    case .leaveMeeting: "Leave Meeting"
    case .reactionLike: "Thumbs Up"
    case .reactionHeart: "Heart"
    case .reactionClap: "Clap"
    case .reactionLaugh: "Laugh"
    case .reactionWow: "Wow"
    case .reactionCelebrate: "Celebrate"
    case .newSession: "New Session"
    case .toggleTerminal: "Toggle Terminal"
    case .newTerminal: "New Terminal"
    case .nextTerminal: "Next Terminal"
    case .previousTerminal: "Previous Terminal"
    case .splitTerminal: "Split Terminal"
    case .focusSidebar: "Focus Sidebar"
    case .focusMainColumn: "Focus Main Column"
    case .focusTerminal: "Focus Terminal"
    case .focusPreviousRegion: "Focus Previous Region"
    case .focusNextRegion: "Focus Next Region"
    case .goToDefinition: "Go to Definition"
    case .goToSymbol: "Go to Symbol"
    case .navigateBack: "Navigate Back"
    case .navigateForward: "Navigate Forward"
    case .formatDocument: "Format Document"
    case .renameSymbol: "Rename Symbol"
    case .findReferences: "Find References"
    case .quickFix: "Quick Fix"
    case .toggleLineComment: "Toggle Line Comment"
    case .moveLineUp: "Move Line Up"
    case .moveLineDown: "Move Line Down"
    case .runProject: "Run Project"
    case .nextIssue: "Next Issue"
    case .previousIssue: "Previous Issue"
    case .commandPalette: "Command Palette"
    case .quickOpen: "Quick Open"
    case .showKeyboardShortcuts: "Keyboard Shortcuts"
    case .hardReload: "Hard Reload"
    case .nextTab: "Next Tab"
    case .previousTab: "Previous Tab"
    case .openDownloads: "Open Downloads"
    case .openDeveloperTools: "Developer Tools"
    case .reopenClosedTab: "Reopen Closed Tab"
    case .quickSwitcher: "Jump to Conversation"
    case .searchMessages: "Search Messages"
    case .newMessage: "New Message"
    case .previousConversation: "Previous Conversation"
    case .nextConversation: "Next Conversation"
    case .openUnreads: "Open Unreads"
    }
  }
}

public enum ActionTarget: String, CaseIterable, Codable, Equatable, Sendable {
  case macOS
  case finder
  case microsoftTeams
  case zoomWorkplace
  case googleMeet
  case codex
  case claude
  case visualStudioCode
  case cursor
  case xcode
  case intellijIdea
  case webStorm
  case rubyMine
  case pyCharm
  case goLand
  case cLion
  case rider
  case androidStudio
  case terminal
  case iTerm2
  case ghostty
  case safari
  case googleChrome
  case firefox
  case microsoftEdge
  case brave
  case arc
  case slack
  case discord
  case cairn

  public var displayName: String {
    switch self {
    case .macOS: "macOS"
    case .finder: "Finder"
    case .microsoftTeams: "Microsoft Teams"
    case .zoomWorkplace: "Zoom Workplace"
    case .googleMeet: "Google Meet"
    case .codex: "Codex"
    case .claude: "Claude"
    case .visualStudioCode: "Visual Studio Code"
    case .cursor: "Cursor"
    case .xcode: "Xcode"
    case .intellijIdea: "IntelliJ IDEA"
    case .webStorm: "WebStorm"
    case .rubyMine: "RubyMine"
    case .pyCharm: "PyCharm"
    case .goLand: "GoLand"
    case .cLion: "CLion"
    case .rider: "Rider"
    case .androidStudio: "Android Studio"
    case .terminal: "Terminal"
    case .iTerm2: "iTerm2"
    case .ghostty: "Ghostty"
    case .safari: "Safari"
    case .googleChrome: "Google Chrome"
    case .firefox: "Firefox"
    case .microsoftEdge: "Microsoft Edge"
    case .brave: "Brave"
    case .arc: "Arc"
    case .slack: "Slack"
    case .discord: "Discord"
    case .cairn: "Cairn"
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

public protocol ApplicationEnablementProviding {
  func isApplicationEnabled(_ target: ActionTarget) -> Bool
}

public struct AllApplicationsEnabled: ApplicationEnablementProviding, Sendable {
  public init() {}

  public func isApplicationEnabled(_ target: ActionTarget) -> Bool {
    true
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
  case disabledApplication(target: ActionTarget)
  case inactiveDomain(domain: ActionDomain, target: ActionTarget)
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
    case .disabledApplication(let target):
      "\(target.displayName) is disabled in QuickDraw"
    case .inactiveDomain(let domain, let target):
      "\(target.displayName) is not active for the \(domain.rawValue) category"
    case .unsupportedAction(let action, let target):
      "\(action.displayName) has no shortcut for \(target.displayName)"
    }
  }
}

public struct ActionRouter {
  private let overrideProvider: any ShortcutOverrideProviding
  private let applicationEnablementProvider: any ApplicationEnablementProviding

  public init(
    overrideProvider: any ShortcutOverrideProviding = NoShortcutOverrides(),
    applicationEnablementProvider: any ApplicationEnablementProviding = AllApplicationsEnabled()
  ) {
    self.overrideProvider = overrideProvider
    self.applicationEnablementProvider = applicationEnablementProvider
  }

  public func route(
    action: Action,
    context: ForegroundContext
  ) -> Result<ActionRoute, ActionRoutingFailure> {
    if ActionCatalog.isSystemWide(action) {
      return routeSystemWide(action: action)
    }

    guard let bundleIdentifier = context.bundleIdentifier else {
      return .failure(.missingBundleIdentifier)
    }

    guard let foregroundTarget = ActionCatalog.target(forBundleIdentifier: bundleIdentifier) else {
      return .failure(.unsupportedApplication(bundleIdentifier: bundleIdentifier))
    }

    let target: ActionTarget
    if let webApplication = ActionCatalog.webApplication(
      in: foregroundTarget,
      domain: action.domain
    ), let webIdentity = webApplication.webApplication {
      guard let activeTabURL = context.activeTabURL else {
        return .failure(.browserContextUnavailable)
      }

      let scheme = activeTabURL.scheme?.lowercased()
      let host = activeTabURL.host?.lowercased()
      guard scheme == webIdentity.scheme.lowercased(), host == webIdentity.host.lowercased() else {
        return .failure(.unsupportedWebPage(host: host))
      }
      target = webApplication.target
    } else {
      guard ActionCatalog.application(for: foregroundTarget).domains.contains(action.domain) else {
        return .failure(.inactiveDomain(domain: action.domain, target: foregroundTarget))
      }
      target = foregroundTarget
    }

    guard applicationEnablementProvider.isApplicationEnabled(target) else {
      return .failure(.disabledApplication(target: target))
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

  private func routeSystemWide(
    action: Action
  ) -> Result<ActionRoute, ActionRoutingFailure> {
    let target = ActionTarget.macOS
    guard applicationEnablementProvider.isApplicationEnabled(target) else {
      return .failure(.disabledApplication(target: target))
    }
    guard let shortcut = shortcut(for: action, target: target) else {
      return .failure(.unsupportedAction(action: action, target: target))
    }
    return .success(ActionRoute(action: action, target: target, shortcut: shortcut))
  }
}
