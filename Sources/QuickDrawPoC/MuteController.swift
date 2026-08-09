import AppKit
import Foundation
import OSLog
import QuickDrawCore

struct MuteStatus {
  let headline: String
  let detail: String
  let target: String
  let isError: Bool
}

final class MuteController {
  var onStatusChange: ((MuteStatus) -> Void)?

  var isEnabled = true {
    didSet {
      publishStateChange(
        headline: isEnabled ? "Enabled — press F6" : "Disabled",
        detail: isEnabled ? permissionSummary : "Mute routing is paused"
      )
    }
  }

  var isDryRunEnabled = false {
    didSet {
      publishStateChange(
        headline: isDryRunEnabled ? "Dry Run enabled" : "Live delivery enabled",
        detail: isDryRunEnabled
          ? "F6 will route and log without sending a shortcut"
          : permissionSummary
      )
    }
  }

  var isHotKeyRegistered = false

  var permissionSummary: String {
    hasPostEventAccess
      ? "Accessibility: Granted"
      : "Accessibility: Required"
  }

  var hasPostEventAccess: Bool {
    shortcutExecutor.hasPostEventAccess
  }

  private let pipeline: MutePipeline
  private let shortcutExecutor: ShortcutExecutor
  private var recentReports: [MutePipelineReport] = []
  private var lastTarget = "Not detected"
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.actionrouter.quickdraw-poc",
    category: "mute-routing"
  )

  init(pipeline: MutePipeline, shortcutExecutor: ShortcutExecutor) {
    self.pipeline = pipeline
    self.shortcutExecutor = shortcutExecutor
  }

  func triggerMute(forceDryRun: Bool = false) {
    guard isEnabled else {
      logger.debug("Mute trigger ignored because QuickDraw is disabled")
      return
    }

    let mode: MuteExecutionMode = forceDryRun || isDryRunEnabled ? .dryRun : .live
    let report = pipeline.run(mode: mode)
    record(report)
    publish(report)
  }

  @discardableResult
  func requestPostEventAccess() -> Bool {
    let granted = shortcutExecutor.requestPostEventAccess()
    publishStateChange(
      headline: granted ? "Accessibility granted" : "Accessibility permission requested",
      detail: granted
        ? "Return to Teams, Zoom, or Meet and press F6"
        : "Enable QuickDraw PoC in System Settings, then try again",
      isError: !granted
    )
    return granted
  }

  func diagnosticsText() -> String {
    var lines = [
      "QuickDraw PoC Diagnostics",
      "generatedAt=\(ISO8601DateFormatter().string(from: Date()))",
      "hotkey.F6=\(isHotKeyRegistered ? "registered" : "notRegistered")",
      "enabled=\(isEnabled)",
      "mode=\(isDryRunEnabled ? "dryRun" : "live")",
      "postEventAccess=\(hasPostEventAccess)",
      "lastTarget=\(lastTarget)",
      "recentReports=\(recentReports.count)",
    ]

    for (index, report) in recentReports.enumerated() {
      lines.append("\(index + 1). \(diagnosticLine(report))")
    }
    lines.append("privacy=No full URLs, tab titles, meeting codes, or keystrokes recorded")
    return lines.joined(separator: "\n")
  }

  private func record(_ report: MutePipelineReport) {
    recentReports.insert(report, at: 0)
    if recentReports.count > 20 {
      recentReports.removeLast(recentReports.count - 20)
    }

    let application = report.application?.bundleIdentifier ?? "unknown"
    let browser = report.browserClassification?.rawValue ?? "notBrowser"
    let latency = String(format: "%.1f", report.latencyMilliseconds)

    switch report.outcome {
    case .delivered(let route):
      logger.info(
        "Mute delivered target=\(route.target.rawValue, privacy: .public) application=\(application, privacy: .public) browser=\(browser, privacy: .public) method=shortcut shortcut=\(route.shortcut.displayValue, privacy: .public) latencyMs=\(latency, privacy: .public)"
      )
    case .dryRun(let route):
      logger.info(
        "Mute dry-run target=\(route.target.rawValue, privacy: .public) application=\(application, privacy: .public) browser=\(browser, privacy: .public) shortcut=\(route.shortcut.displayValue, privacy: .public) latencyMs=\(latency, privacy: .public)"
      )
    case .failed(let failure):
      logger.error(
        "Mute failed reason=\(failure.userMessage, privacy: .public) application=\(application, privacy: .public) browser=\(browser, privacy: .public) latencyMs=\(latency, privacy: .public)"
      )
    }
  }

  private func publish(_ report: MutePipelineReport) {
    let latency = String(format: "%.1f ms", report.latencyMilliseconds)

    switch report.outcome {
    case .delivered(let route):
      lastTarget = route.target.displayName
      publish(
        headline: "Mute delivered",
        detail: "\(route.shortcut.displayValue) · \(latency)",
        target: route.target.displayName,
        isError: false
      )

    case .dryRun(let route):
      lastTarget = route.target.displayName
      publish(
        headline: "Dry Run route matched",
        detail: "Would send \(route.shortcut.displayValue) · \(latency)",
        target: route.target.displayName,
        isError: false
      )

    case .failed(let failure):
      lastTarget = targetDescription(report)
      publish(
        headline: "Mute not delivered",
        detail: "\(failure.userMessage) · \(latency)",
        target: lastTarget,
        isError: true
      )
    }
  }

  private func publishStateChange(
    headline: String,
    detail: String,
    isError: Bool = false
  ) {
    publish(
      headline: headline,
      detail: detail,
      target: lastTarget,
      isError: isError
    )
  }

  private func publish(
    headline: String,
    detail: String,
    target: String,
    isError: Bool
  ) {
    onStatusChange?(
      MuteStatus(
        headline: headline,
        detail: detail,
        target: target,
        isError: isError
      )
    )
  }

  private func targetDescription(_ report: MutePipelineReport) -> String {
    if let browser = report.browserClassification {
      return browser.displayName
    }
    return report.application?.bundleIdentifier ?? "Not detected"
  }

  private func diagnosticLine(_ report: MutePipelineReport) -> String {
    let application = report.application?.bundleIdentifier ?? "unknown"
    let browser = report.browserClassification?.rawValue ?? "notBrowser"
    let latency = String(format: "%.1fms", report.latencyMilliseconds)

    let outcome: String
    switch report.outcome {
    case .delivered(let route):
      outcome = "delivered target=\(route.target.rawValue) shortcut=\(route.shortcut.displayValue)"
    case .dryRun(let route):
      outcome = "dryRun target=\(route.target.rawValue) shortcut=\(route.shortcut.displayValue)"
    case .failed(let failure):
      outcome = "failed reason=\(failure.userMessage)"
    }

    return
      "mode=\(report.mode.rawValue) application=\(application) browser=\(browser) \(outcome) latency=\(latency)"
  }
}
