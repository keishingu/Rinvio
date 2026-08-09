import AppKit
import Combine
import Foundation

enum QuickDrawSection: String, CaseIterable, Identifiable {
  case actions
  case applications
  case diagnostics

  var id: Self { self }

  var title: String {
    switch self {
    case .actions: "Actions"
    case .applications: "Applications"
    case .diagnostics: "Diagnostics"
    }
  }

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
  let name: String
  let compactName: String
  let systemImage: String
  let identity: String
  let shortcut: String
  let executionDetail: String
  let isInstalled: Bool

  static func current() -> [ApplicationMapping] {
    let workspace = NSWorkspace.shared
    return [
      ApplicationMapping(
        id: "microsoftTeams",
        name: "Microsoft Teams",
        compactName: "Teams",
        systemImage: "person.2.fill",
        identity: "com.microsoft.teams2",
        shortcut: "⌘⇧M",
        executionDetail: "Official keyboard shortcut",
        isInstalled: workspace.urlForApplication(withBundleIdentifier: "com.microsoft.teams2")
          != nil
          || workspace.urlForApplication(withBundleIdentifier: "com.microsoft.teams") != nil
      ),
      ApplicationMapping(
        id: "zoomWorkplace",
        name: "Zoom Workplace",
        compactName: "Zoom",
        systemImage: "video.fill",
        identity: "us.zoom.xos",
        shortcut: "⌘⇧A",
        executionDetail: "Official keyboard shortcut",
        isInstalled: workspace.urlForApplication(withBundleIdentifier: "us.zoom.xos") != nil
      ),
      ApplicationMapping(
        id: "googleMeet",
        name: "Google Meet",
        compactName: "Meet",
        systemImage: "globe",
        identity: "meet.google.com in Google Chrome",
        shortcut: "⌘D",
        executionDetail: "Active tab detection + official shortcut",
        isInstalled: workspace.urlForApplication(withBundleIdentifier: "com.google.Chrome") != nil
      ),
    ]
  }
}

@MainActor
final class QuickDrawAppModel: ObservableObject {
  @Published private(set) var isEnabled = true
  @Published private(set) var isDryRunEnabled = false
  @Published private(set) var hasAccessibilityPermission = false
  @Published private(set) var isHotKeyRegistered = false
  @Published private(set) var status = MuteStatus(
    headline: "Starting…",
    detail: "Preparing F6",
    target: "Not detected",
    isError: false
  )
  @Published private(set) var diagnostics = "QuickDraw Diagnostics are not available yet."
  @Published private(set) var applications = ApplicationMapping.current()

  var onSetEnabled: ((Bool) -> Void)?
  var onSetDryRun: ((Bool) -> Void)?
  var onRunDryCheck: (() -> Void)?
  var onRequestAccessibility: (() -> Void)?
  var onRefreshPermission: (() -> Bool)?
  var onRefreshDiagnostics: (() -> String)?

  func setEnabled(_ enabled: Bool) {
    isEnabled = enabled
    onSetEnabled?(enabled)
  }

  func setDryRunEnabled(_ enabled: Bool) {
    isDryRunEnabled = enabled
    onSetDryRun?(enabled)
  }

  func runDryCheck() {
    onRunDryCheck?()
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
    status: MuteStatus,
    hasAccessibilityPermission: Bool,
    diagnostics: String
  ) {
    self.status = status
    self.hasAccessibilityPermission = hasAccessibilityPermission
    self.diagnostics = diagnostics
  }

  func setHotKeyRegistered(_ registered: Bool) {
    isHotKeyRegistered = registered
  }
}
