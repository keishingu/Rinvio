import AppKit
import Carbon
import Combine
import Foundation
import QuickDrawCore

enum QuickDrawSection: String, CaseIterable, Identifiable {
  case actions
  case applications
  case diagnostics

  var id: Self { self }

  var systemImage: String {
    switch self {
    case .actions: "bolt"
    case .applications: "square.grid.2x2"
    case .diagnostics: "waveform.path.ecg"
    }
  }
}

struct ApplicationMapping: Identifiable, Equatable {
  let id: String
  let target: ActionTarget
  let name: String
  let compactName: String
  let systemImage: String
  let identity: String
  let isInstalled: Bool

  static func current() -> [ApplicationMapping] {
    let workspace = NSWorkspace.shared
    return [
      ApplicationMapping(
        id: "microsoftTeams",
        target: .microsoftTeams,
        name: "Microsoft Teams",
        compactName: "Teams",
        systemImage: "person.2.fill",
        identity: "com.microsoft.teams2",
        isInstalled: workspace.urlForApplication(withBundleIdentifier: "com.microsoft.teams2")
          != nil
          || workspace.urlForApplication(withBundleIdentifier: "com.microsoft.teams") != nil
      ),
      ApplicationMapping(
        id: "zoomWorkplace",
        target: .zoomWorkplace,
        name: "Zoom Workplace",
        compactName: "Zoom",
        systemImage: "video.fill",
        identity: "us.zoom.xos",
        isInstalled: workspace.urlForApplication(withBundleIdentifier: "us.zoom.xos") != nil
      ),
      ApplicationMapping(
        id: "googleMeet",
        target: .googleMeet,
        name: "Google Meet",
        compactName: "Meet",
        systemImage: "globe",
        identity: "meet.google.com in Google Chrome",
        isInstalled: workspace.urlForApplication(withBundleIdentifier: "com.google.Chrome") != nil
      ),
    ]
  }
}

struct ActionDefinition: Identifiable, Equatable {
  let action: MeetingAction
  let systemImage: String

  var id: String { action.rawValue }
  static let all: [ActionDefinition] = [
    ActionDefinition(action: .mute, systemImage: "mic.slash.fill"),
    ActionDefinition(action: .camera, systemImage: "video.fill"),
    ActionDefinition(action: .raiseHand, systemImage: "hand.raised.fill"),
  ]
}

enum ShortcutRecordingDestination: Equatable {
  case trigger(MeetingAction)
  case application(MeetingAction, ActionTarget)
}

@MainActor
final class QuickDrawAppModel: ObservableObject {
  @Published private(set) var language: AppLanguage
  @Published private(set) var isEnabled = true
  @Published private(set) var isDryRunEnabled = false
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
  private var localKeyMonitor: Any?

  var onSetEnabled: ((Bool) -> Void)?
  var onSetDryRun: ((Bool) -> Void)?
  var onRunDryCheck: ((MeetingAction) -> Void)?
  var onRequestAccessibility: (() -> Void)?
  var onRefreshPermission: (() -> Bool)?
  var onRefreshDiagnostics: (() -> String)?
  var onLanguageChange: ((AppLanguage) -> Void)?
  var onShortcutRecordingBegan: (() -> Void)?
  var onShortcutRecordingEnded: (() -> String?)?
  var onApplyTrigger: ((MeetingAction, KeyStroke) -> String?)?
  var onResetTrigger: ((MeetingAction) -> String?)?
  var onResetAction: ((MeetingAction) -> String?)?

  init(
    defaults: UserDefaults = .standard,
    configurationStore: QuickDrawConfigurationStore = QuickDrawConfigurationStore()
  ) {
    self.defaults = defaults
    self.configurationStore = configurationStore
    language = AppLanguage.preferred(defaults: defaults)
    configuration = configurationStore.configuration
  }

  var copy: QuickDrawCopy {
    QuickDrawCopy(language: language)
  }

  var localizedStatus: ActionStatus {
    copy.localizedStatus(status)
  }

  var triggerSummary: String {
    MeetingAction.allCases.map {
      "\(trigger(for: $0).displayValue) \(copy.actionName($0))"
    }.joined(separator: " · ")
  }

  var registeredTriggerSummary: String {
    MeetingAction.allCases.map { trigger(for: $0).displayValue }.joined(separator: "／")
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

  func runDryCheck(action: MeetingAction) {
    onRunDryCheck?(action)
  }

  func trigger(for action: MeetingAction) -> KeyStroke {
    configurationStore.trigger(for: action)
  }

  func isTriggerOverridden(for action: MeetingAction) -> Bool {
    configurationStore.isTriggerOverridden(for: action)
  }

  func shortcut(for action: MeetingAction, target: ActionTarget) -> KeyStroke {
    configurationStore.shortcut(for: action, target: target)
  }

  func isShortcutOverridden(for action: MeetingAction, target: ActionTarget) -> Bool {
    configurationStore.isShortcutOverridden(for: action, target: target)
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

  func resetTrigger(for action: MeetingAction) {
    shortcutEditingError = onResetTrigger?(action)
    syncConfiguration()
  }

  func resetShortcut(for action: MeetingAction, target: ActionTarget) {
    do {
      try configurationStore.resetShortcut(for: action, target: target)
      shortcutEditingError = nil
      syncConfiguration()
    } catch {
      shortcutEditingError = error.localizedDescription
    }
  }

  func resetAction(_ action: MeetingAction) {
    shortcutEditingError = onResetAction?(action)
    syncConfiguration()
  }

  func hasOverrides(for action: MeetingAction) -> Bool {
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
