import AppKit
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

  func shortcut(for action: MeetingAction) -> String {
    ActionRouter().shortcut(for: action, target: target).displayValue
  }

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
  var trigger: String { action.triggerDisplayValue }

  static let all: [ActionDefinition] = [
    ActionDefinition(action: .mute, systemImage: "mic.slash.fill"),
    ActionDefinition(action: .camera, systemImage: "video.fill"),
    ActionDefinition(action: .raiseHand, systemImage: "hand.raised.fill"),
  ]
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
    detail: "Preparing F6/F7/F8",
    target: "Not detected",
    isError: false
  )
  @Published private(set) var diagnostics = "QuickDraw Diagnostics are not available yet."
  @Published private(set) var applications = ApplicationMapping.current()
  let actions = ActionDefinition.all

  private let defaults: UserDefaults

  var onSetEnabled: ((Bool) -> Void)?
  var onSetDryRun: ((Bool) -> Void)?
  var onRunDryCheck: ((MeetingAction) -> Void)?
  var onRequestAccessibility: (() -> Void)?
  var onRefreshPermission: (() -> Bool)?
  var onRefreshDiagnostics: (() -> String)?
  var onLanguageChange: ((AppLanguage) -> Void)?

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    language = AppLanguage.preferred(defaults: defaults)
  }

  var copy: QuickDrawCopy {
    QuickDrawCopy(language: language)
  }

  var localizedStatus: ActionStatus {
    copy.localizedStatus(status)
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
}
