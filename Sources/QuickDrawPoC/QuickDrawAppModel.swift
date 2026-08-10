import AppKit
import Carbon
import Combine
import Foundation
import QuickDrawCore

enum QuickDrawSection: String, CaseIterable, Identifiable {
  case meeting
  case chat
  case development
  case browser
  case applications
  case settings
  case diagnostics

  var id: Self { self }

  var systemImage: String {
    switch self {
    case .meeting: "person.2.fill"
    case .chat: "bubble.left.and.bubble.right.fill"
    case .development: "wrench.and.screwdriver.fill"
    case .browser: "globe"
    case .applications: "square.grid.2x2"
    case .settings: "gearshape"
    case .diagnostics: "waveform.path.ecg"
    }
  }

  var actionDomain: ActionDomain? {
    switch self {
    case .meeting: .meeting
    case .chat: .chat
    case .development: .development
    case .browser: .browser
    case .applications, .settings, .diagnostics: nil
    }
  }

  static let actionSections: [QuickDrawSection] = [.meeting, .chat, .development, .browser]
  static let utilitySections: [QuickDrawSection] = [.applications, .settings, .diagnostics]
}

struct ApplicationMapping: Identifiable, Equatable {
  let id: String
  let target: ActionTarget
  let name: String
  let compactName: String
  let systemImage: String
  let identity: String
  let isInstalled: Bool
  let domains: [ActionDomain]

  static func current() -> [ApplicationMapping] {
    let workspace = NSWorkspace.shared
    let presentations: [(ActionTarget, compactName: String, systemImage: String)] = [
      (.microsoftTeams, "Teams", "person.2.fill"),
      (.zoomWorkplace, "Zoom", "video.fill"),
      (.googleMeet, "Meet", "globe"),
      (.codex, "Codex", "chevron.left.forwardslash.chevron.right"),
      (.claude, "Claude", "terminal.fill"),
      (.visualStudioCode, "VS Code", "chevron.left.forwardslash.chevron.right"),
      (.cursor, "Cursor", "cursorarrow.rays"),
      (.terminal, "Terminal", "terminal.fill"),
      (.iTerm2, "iTerm2", "terminal"),
      (.safari, "Safari", "safari.fill"),
      (.googleChrome, "Chrome", "globe"),
      (.slack, "Slack", "bubble.left.and.bubble.right.fill"),
      (.discord, "Discord", "bubble.left.and.bubble.right.fill"),
      (.cairn, "Cairn", "mountain.2.fill"),
    ]

    return presentations.map { target, compactName, systemImage in
      let application = ActionCatalog.application(for: target)
      let installationTarget = application.webApplication?.browserTarget ?? target
      let installationBundleIdentifiers =
        ActionCatalog.application(for: installationTarget).bundleIdentifiers
      let identity =
        application.webApplication.map {
          "\($0.host) in \($0.browserTarget.displayName)"
        } ?? application.bundleIdentifiers.first ?? target.rawValue

      return ApplicationMapping(
        id: target.rawValue,
        target: target,
        name: target.displayName,
        compactName: compactName,
        systemImage: systemImage,
        identity: identity,
        isInstalled: installationBundleIdentifiers.contains {
          workspace.urlForApplication(withBundleIdentifier: $0) != nil
        },
        domains: application.domains
      )
    }
  }
}

enum ActionCategory: String, CaseIterable, Identifiable {
  case meetingControls
  case panelsAndSharing
  case reactions
  case agentSessions
  case terminals
  case commandsAndNavigation
  case pageLoading
  case tabs
  case browserTools
  case conversationNavigation
  case messaging

  var id: Self { self }
}

struct ActionDefinition: Identifiable, Equatable {
  let action: Action
  let systemImage: String
  let category: ActionCategory

  var id: String { action.rawValue }
  var domain: ActionDomain { action.domain }
  static let all: [ActionDefinition] = [
    ActionDefinition(action: .mute, systemImage: "mic.slash.fill", category: .meetingControls),
    ActionDefinition(action: .camera, systemImage: "video.fill", category: .meetingControls),
    ActionDefinition(
      action: .raiseHand, systemImage: "hand.raised.fill", category: .meetingControls),
    ActionDefinition(
      action: .switchCamera,
      systemImage: "arrow.triangle.2.circlepath.camera",
      category: .meetingControls
    ),
    ActionDefinition(
      action: .openChat,
      systemImage: "bubble.left.and.bubble.right.fill",
      category: .panelsAndSharing
    ),
    ActionDefinition(
      action: .showParticipants,
      systemImage: "person.2.fill",
      category: .panelsAndSharing
    ),
    ActionDefinition(
      action: .toggleCaptions,
      systemImage: "captions.bubble.fill",
      category: .panelsAndSharing
    ),
    ActionDefinition(
      action: .shareScreen,
      systemImage: "rectangle.on.rectangle.angled",
      category: .panelsAndSharing
    ),
    ActionDefinition(
      action: .pictureInPicture,
      systemImage: "pip",
      category: .panelsAndSharing
    ),
    ActionDefinition(
      action: .leaveMeeting,
      systemImage: "rectangle.portrait.and.arrow.right",
      category: .meetingControls
    ),
    ActionDefinition(
      action: .reactionLike,
      systemImage: "hand.thumbsup.fill",
      category: .reactions
    ),
    ActionDefinition(action: .reactionHeart, systemImage: "heart.fill", category: .reactions),
    ActionDefinition(action: .reactionClap, systemImage: "hands.clap.fill", category: .reactions),
    ActionDefinition(action: .reactionLaugh, systemImage: "face.smiling", category: .reactions),
    ActionDefinition(action: .reactionWow, systemImage: "sparkles", category: .reactions),
    ActionDefinition(
      action: .reactionCelebrate,
      systemImage: "party.popper.fill",
      category: .reactions
    ),
    ActionDefinition(
      action: .newSession,
      systemImage: "plus.bubble.fill",
      category: .agentSessions
    ),
    ActionDefinition(
      action: .toggleTerminal,
      systemImage: "terminal.fill",
      category: .terminals
    ),
    ActionDefinition(
      action: .newTerminal,
      systemImage: "plus.rectangle.on.rectangle",
      category: .terminals
    ),
    ActionDefinition(
      action: .nextTerminal,
      systemImage: "arrow.right.to.line",
      category: .terminals
    ),
    ActionDefinition(
      action: .previousTerminal,
      systemImage: "arrow.left.to.line",
      category: .terminals
    ),
    ActionDefinition(
      action: .splitTerminal,
      systemImage: "rectangle.split.2x1",
      category: .terminals
    ),
    ActionDefinition(
      action: .focusSidebar,
      systemImage: "sidebar.left",
      category: .commandsAndNavigation
    ),
    ActionDefinition(
      action: .focusMainColumn,
      systemImage: "rectangle.fill",
      category: .commandsAndNavigation
    ),
    ActionDefinition(
      action: .focusTerminal,
      systemImage: "terminal.fill",
      category: .commandsAndNavigation
    ),
    ActionDefinition(
      action: .commandPalette,
      systemImage: "command",
      category: .commandsAndNavigation
    ),
    ActionDefinition(
      action: .quickOpen,
      systemImage: "doc.text.magnifyingglass",
      category: .commandsAndNavigation
    ),
    ActionDefinition(
      action: .showKeyboardShortcuts,
      systemImage: "keyboard",
      category: .commandsAndNavigation
    ),
    ActionDefinition(
      action: .hardReload,
      systemImage: "arrow.clockwise.circle.fill",
      category: .pageLoading
    ),
    ActionDefinition(
      action: .nextTab,
      systemImage: "arrow.right.to.line",
      category: .tabs
    ),
    ActionDefinition(
      action: .previousTab,
      systemImage: "arrow.left.to.line",
      category: .tabs
    ),
    ActionDefinition(
      action: .reopenClosedTab,
      systemImage: "arrow.uturn.backward.circle.fill",
      category: .tabs
    ),
    ActionDefinition(
      action: .openDownloads,
      systemImage: "arrow.down.circle.fill",
      category: .browserTools
    ),
    ActionDefinition(
      action: .openDeveloperTools,
      systemImage: "hammer.fill",
      category: .browserTools
    ),
    ActionDefinition(
      action: .quickSwitcher,
      systemImage: "arrow.triangle.swap",
      category: .conversationNavigation
    ),
    ActionDefinition(
      action: .searchMessages,
      systemImage: "magnifyingglass",
      category: .conversationNavigation
    ),
    ActionDefinition(
      action: .previousConversation,
      systemImage: "arrow.up",
      category: .conversationNavigation
    ),
    ActionDefinition(
      action: .nextConversation,
      systemImage: "arrow.down",
      category: .conversationNavigation
    ),
    ActionDefinition(
      action: .newMessage,
      systemImage: "square.and.pencil",
      category: .messaging
    ),
    ActionDefinition(
      action: .openUnreads,
      systemImage: "tray.full.fill",
      category: .messaging
    ),
  ]
}

enum ShortcutRecordingDestination: Equatable {
  case trigger(Action)
  case application(Action, ActionTarget)
}

@MainActor
final class QuickDrawAppModel: ObservableObject {
  private static let cheatSheetEnabledKey = "cheatSheetEnabled"

  @Published private(set) var language: AppLanguage
  @Published private(set) var isEnabled = true
  @Published private(set) var isDryRunEnabled = false
  @Published private(set) var isCheatSheetEnabled: Bool
  @Published private(set) var hasAccessibilityPermission = false
  @Published private(set) var areHotKeysRegistered = false
  @Published private(set) var status = ActionStatus(
    action: nil,
    headline: "Starting…",
    detail: "Preparing shortcuts",
    target: "Not detected",
    isError: false
  )
  @Published private(set) var diagnostics = "QuickDraw Diagnostics are not available yet."
  @Published private(set) var applications = ApplicationMapping.current()
  @Published private(set) var configuration: QuickDrawConfiguration
  @Published private(set) var recordingDestination: ShortcutRecordingDestination?
  @Published private(set) var shortcutEditingError: String?
  let actions = ActionDefinition.all

  private let defaults: UserDefaults
  private let configurationStore: QuickDrawConfigurationStore
  private let configuredSystemShortcutDetector: ConfiguredSystemShortcutDetector
  private var localKeyMonitor: Any?

  var onSetEnabled: ((Bool) -> Void)?
  var onSetDryRun: ((Bool) -> Void)?
  var onSetCheatSheetEnabled: ((Bool) -> Void)?
  var onPreviewCheatSheet: (() -> Void)?
  var onRunDryCheck: ((Action) -> Void)?
  var onRequestAccessibility: (() -> Void)?
  var onRefreshPermission: (() -> Bool)?
  var onRefreshDiagnostics: (() -> String)?
  var onLanguageChange: ((AppLanguage) -> Void)?
  var onShortcutRecordingBegan: (() -> Void)?
  var onShortcutRecordingEnded: (() -> String?)?
  var onApplyTrigger: ((Action, KeyStroke) -> String?)?
  var onResetTrigger: ((Action) -> String?)?
  var onResetAction: ((Action) -> String?)?

  init(
    defaults: UserDefaults = .standard,
    configurationStore: QuickDrawConfigurationStore = QuickDrawConfigurationStore(),
    configuredSystemShortcutDetector: ConfiguredSystemShortcutDetector =
      ConfiguredSystemShortcutDetector()
  ) {
    self.defaults = defaults
    self.configurationStore = configurationStore
    self.configuredSystemShortcutDetector = configuredSystemShortcutDetector
    language = AppLanguage.preferred(defaults: defaults)
    isCheatSheetEnabled =
      defaults.object(forKey: Self.cheatSheetEnabledKey) as? Bool ?? true
    configuration = configurationStore.configuration
  }

  var copy: QuickDrawCopy {
    QuickDrawCopy(language: language)
  }

  var localizedStatus: ActionStatus {
    copy.localizedStatus(status)
  }

  var triggerSummary: String {
    copy.assignedTriggerCount(Action.allCases.count { trigger(for: $0) != nil })
  }

  var registeredTriggerSummary: String {
    Action.allCases.compactMap { trigger(for: $0)?.displayValue }.joined(separator: "／")
  }

  func setLanguage(_ language: AppLanguage) {
    self.language = language
    defaults.set(language.rawValue, forKey: AppLanguage.defaultsKey)
    onLanguageChange?(language)
  }

  func setEnabled(_ enabled: Bool) {
    isEnabled = enabled
    onSetEnabled?(enabled)
  }

  func setDryRunEnabled(_ enabled: Bool) {
    isDryRunEnabled = enabled
    onSetDryRun?(enabled)
  }

  func setCheatSheetEnabled(_ enabled: Bool) {
    isCheatSheetEnabled = enabled
    defaults.set(enabled, forKey: Self.cheatSheetEnabledKey)
    onSetCheatSheetEnabled?(enabled)
  }

  func previewCheatSheet() {
    onPreviewCheatSheet?()
  }

  func runDryCheck(action: Action) {
    onRunDryCheck?(action)
  }

  func trigger(for action: Action) -> KeyStroke? {
    configurationStore.trigger(for: action)
  }

  func isTriggerOverridden(for action: Action) -> Bool {
    configurationStore.isTriggerOverridden(for: action)
  }

  func triggerConflicts(for action: Action) -> [TriggerConflict] {
    guard let trigger = trigger(for: action) else { return [] }

    if let knownConflict = SystemShortcutCatalog.knownConflict(for: trigger) {
      return [.knownSystemShortcut(knownConflict)]
    }
    if configuredSystemShortcutDetector.conflicts(with: trigger) {
      return [.configuredSystemShortcut]
    }
    return []
  }

  func shortcut(for action: Action, target: ActionTarget) -> KeyStroke? {
    configurationStore.shortcut(for: action, target: target)
  }

  func isShortcutOverridden(for action: Action, target: ActionTarget) -> Bool {
    configurationStore.isShortcutOverridden(for: action, target: target)
  }

  func actions(in domain: ActionDomain) -> [ActionDefinition] {
    actions.filter { $0.domain == domain }
  }

  func applications(in domain: ActionDomain) -> [ApplicationMapping] {
    applications.filter { $0.domains.contains(domain) }
  }

  func supportedActionCount(for target: ActionTarget) -> Int {
    actions.count { shortcut(for: $0.action, target: target) != nil }
  }

  func beginRecording(_ destination: ShortcutRecordingDestination) {
    cancelRecording()
    shortcutEditingError = nil
    recordingDestination = destination
    onShortcutRecordingBegan?()
    localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
      [weak self] event in
      guard let self else { return event }
      if event.keyCode == UInt16(kVK_Escape) {
        self.cancelRecording()
        return nil
      }
      guard let shortcut = ShortcutCapture.keyStroke(from: event) else {
        self.shortcutEditingError = self.copy.shortcutCouldNotBeRead
        return nil
      }
      self.capture(shortcut)
      return nil
    }
  }

  func cancelRecording() {
    guard recordingDestination != nil || localKeyMonitor != nil else { return }
    removeLocalKeyMonitor()
    recordingDestination = nil
    if let error = onShortcutRecordingEnded?() {
      shortcutEditingError = error
    }
  }

  func resetTrigger(for action: Action) {
    shortcutEditingError = onResetTrigger?(action)
    syncConfiguration()
  }

  func resetShortcut(for action: Action, target: ActionTarget) {
    do {
      try configurationStore.resetShortcut(for: action, target: target)
      shortcutEditingError = nil
      syncConfiguration()
    } catch {
      shortcutEditingError = error.localizedDescription
    }
  }

  func resetAction(_ action: Action) {
    shortcutEditingError = onResetAction?(action)
    syncConfiguration()
  }

  func hasOverrides(for action: Action) -> Bool {
    isTriggerOverridden(for: action)
      || ActionTarget.allCases.contains { isShortcutOverridden(for: action, target: $0) }
  }

  func requestAccessibility() {
    onRequestAccessibility?()
    refreshPermission()
  }

  func refreshPermission() {
    if let onRefreshPermission {
      hasAccessibilityPermission = onRefreshPermission()
    }
    refreshDiagnostics()
  }

  func refreshEnvironment() {
    applications = ApplicationMapping.current()
    configuredSystemShortcutDetector.refresh()
    syncConfiguration()
    refreshPermission()
  }

  func refreshDiagnostics() {
    if let onRefreshDiagnostics {
      diagnostics = onRefreshDiagnostics()
    }
  }

  func update(
    status: ActionStatus,
    hasAccessibilityPermission: Bool,
    diagnostics: String
  ) {
    self.status = status
    self.hasAccessibilityPermission = hasAccessibilityPermission
    self.diagnostics = diagnostics
  }

  func setHotKeysRegistered(_ registered: Bool) {
    areHotKeysRegistered = registered
  }

  private func capture(_ shortcut: KeyStroke) {
    guard let destination = recordingDestination else { return }
    removeLocalKeyMonitor()
    recordingDestination = nil

    switch destination {
    case .trigger(let action):
      shortcutEditingError = onApplyTrigger?(action, shortcut)
    case .application(let action, let target):
      do {
        try configurationStore.setShortcutOverride(shortcut, for: action, target: target)
        shortcutEditingError = onShortcutRecordingEnded?()
      } catch {
        shortcutEditingError = error.localizedDescription
        _ = onShortcutRecordingEnded?()
      }
    }
    syncConfiguration()
  }

  private func syncConfiguration() {
    configuration = configurationStore.configuration
  }

  private func removeLocalKeyMonitor() {
    if let localKeyMonitor {
      NSEvent.removeMonitor(localKeyMonitor)
      self.localKeyMonitor = nil
    }
  }
}
