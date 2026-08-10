import AppKit
import Foundation
import OSLog
import QuickDrawCore

struct ActionStatus {
  let action: Action?
  let headline: String
  let detail: String
  let target: String
  let isError: Bool
}

final class ActionController {
  var onStatusChange: ((ActionStatus) -> Void)?

  var isEnabled = true {
    didSet {
      publishStateChange(
        headline: isEnabled ? "Enabled — shortcuts ready" : "Disabled",
        detail: isEnabled ? permissionSummary : "Action routing is paused"
      )
    }
  }

  var isDryRunEnabled = false {
    didSet {
      publishStateChange(
        headline: isDryRunEnabled ? "Dry Run enabled" : "Live delivery enabled",
        detail: isDryRunEnabled
          ? "Configured triggers will route and log without sending a shortcut"
          : permissionSummary
      )
    }
  }

  var areHotKeysRegistered = false
  var triggerSummary = "F6/F7/F8"

  var permissionSummary: String {
    hasPostEventAccess ? "Accessibility: Granted" : "Accessibility: Required"
  }

  var hasPostEventAccess: Bool {
    shortcutExecutor.hasPostEventAccess
  }

  private let pipeline: ActionPipeline
  private let shortcutExecutor: ShortcutExecutor
  private var recentReports: [ActionPipelineReport] = []
  private var lastTarget = "Not detected"
  private var lastAction: Action?
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.actionrouter.quickdraw-poc",
    category: "action-routing"
  )

  init(pipeline: ActionPipeline, shortcutExecutor: ShortcutExecutor) {
    self.pipeline = pipeline
    self.shortcutExecutor = shortcutExecutor
  }

  @discardableResult
  func trigger(_ action: Action, forceDryRun: Bool = false) -> Bool {
    trigger([action], forceDryRun: forceDryRun)
  }

  @discardableResult
  func trigger(_ candidateActions: [Action], forceDryRun: Bool = false) -> Bool {
    guard isEnabled else {
      logger.debug("Action trigger ignored because QuickDraw is disabled")
      return false
    }

    let mode: ActionExecutionMode = forceDryRun || isDryRunEnabled ? .dryRun : .live
    for action in candidateActions {
      let report = pipeline.run(action: action, mode: mode)
      let consumesTrigger = forceDryRun || report.outcome.consumesTrigger
      guard consumesTrigger else { continue }
      record(report)
      publish(report)
      return true
    }
    logger.debug("Shortcut passed through because no QuickDraw target matched")
    return false
  }

  @discardableResult
  func requestPostEventAccess() -> Bool {
    let granted = shortcutExecutor.requestPostEventAccess()
    publishStateChange(
      headline: granted ? "Accessibility granted" : "Accessibility permission requested",
      detail: granted
        ? "Return to a supported application and use a configured trigger"
        : "Enable QuickDraw PoC in System Settings, then try again",
      isError: !granted
    )
    return granted
  }

  func diagnosticsText() -> String {
    var lines = [
      "QuickDraw PoC Diagnostics",
      "generatedAt=\(ISO8601DateFormatter().string(from: Date()))",
      "hotkeys=\(areHotKeysRegistered ? "registered" : "notRegistered") \(triggerSummary)",
      "enabled=\(isEnabled)",
      "mode=\(isDryRunEnabled ? "dryRun" : "live")",
      "postEventAccess=\(hasPostEventAccess)",
      "lastAction=\(lastAction?.rawValue ?? "none")",
      "lastTarget=\(lastTarget)",
      "recentReports=\(recentReports.count)",
    ]

    for (index, report) in recentReports.enumerated() {
      lines.append("\(index + 1). \(diagnosticLine(report))")
    }
    lines.append("privacy=No full URLs, tab titles, meeting codes, or keystrokes recorded")
    return lines.joined(separator: "\n")
  }

  private func record(_ report: ActionPipelineReport) {
    recentReports.insert(report, at: 0)
    if recentReports.count > 20 {
      recentReports.removeLast(recentReports.count - 20)
    }

    let application = report.application?.bundleIdentifier ?? "unknown"
    let browser = report.browserClassification?.rawValue ?? "notBrowser"
    let latency = String(format: "%.1f", report.latencyMilliseconds)
    let action = report.action.rawValue

    switch report.outcome {
    case .delivered(let route):
      logger.info(
        "Action delivered action=\(action, privacy: .public) target=\(route.target.rawValue, privacy: .public) application=\(application, privacy: .public) browser=\(browser, privacy: .public) method=shortcut shortcut=\(route.shortcut.displayValue, privacy: .public) latencyMs=\(latency, privacy: .public)"
      )
    case .dryRun(let route):
      logger.info(
        "Action dry-run action=\(action, privacy: .public) target=\(route.target.rawValue, privacy: .public) application=\(application, privacy: .public) browser=\(browser, privacy: .public) shortcut=\(route.shortcut.displayValue, privacy: .public) latencyMs=\(latency, privacy: .public)"
      )
    case .failed(let failure):
      logger.error(
        "Action failed action=\(action, privacy: .public) reason=\(failure.userMessage, privacy: .public) application=\(application, privacy: .public) browser=\(browser, privacy: .public) latencyMs=\(latency, privacy: .public)"
      )
    }
  }

  private func publish(_ report: ActionPipelineReport) {
    let latency = String(format: "%.1f ms", report.latencyMilliseconds)
    lastAction = report.action

    switch report.outcome {
    case .delivered(let route):
      lastTarget = route.target.displayName
      publish(
        action: report.action,
        headline: "\(report.action.displayName) delivered",
        detail: "\(route.shortcut.displayValue) · \(latency)",
        target: route.target.displayName,
        isError: false
      )

    case .dryRun(let route):
      lastTarget = route.target.displayName
      publish(
        action: report.action,
        headline: "Dry Run route matched",
        detail:
          "\(report.action.displayName) would send \(route.shortcut.displayValue) · \(latency)",
        target: route.target.displayName,
        isError: false
      )

    case .failed(let failure):
      lastTarget = targetDescription(report)
      publish(
        action: report.action,
        headline: "\(report.action.displayName) not delivered",
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
      action: lastAction,
      headline: headline,
      detail: detail,
      target: lastTarget,
      isError: isError
    )
  }

  private func publish(
    action: Action?,
    headline: String,
    detail: String,
    target: String,
    isError: Bool
  ) {
    onStatusChange?(
      ActionStatus(
        action: action,
        headline: headline,
        detail: detail,
        target: target,
        isError: isError
      )
    )
  }

  private func targetDescription(_ report: ActionPipelineReport) -> String {
    if let browser = report.browserClassification {
      return browser.displayName
    }
    return report.application?.bundleIdentifier ?? "Not detected"
  }

  private func diagnosticLine(_ report: ActionPipelineReport) -> String {
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
      "action=\(report.action.rawValue) mode=\(report.mode.rawValue) application=\(application) browser=\(browser) \(outcome) latency=\(latency)"
  }
}
