import AppKit
import Foundation
import QuickDrawCore

enum BrowserContextError: LocalizedError {
  case scriptCreationFailed
  case executionFailed(code: Int?, message: String)
  case emptyURL
  case malformedURL

  var errorDescription: String? {
    switch self {
    case .scriptCreationFailed:
      return "Chrome active-tab query could not be created"
    case .executionFailed(let code, let message):
      if code == -1743 {
        return "Chrome Automation permission is required"
      }
      return "Chrome active-tab query failed: \(message)"
    case .emptyURL:
      return "Chrome has no readable active tab"
    case .malformedURL:
      return "Chrome returned an invalid active-tab URL"
    }
  }
}

final class ChromeActiveTabProvider: ActiveTabURLProviding {
  private let script: NSAppleScript?

  init() {
    script = NSAppleScript(
      source: """
        tell application id "com.google.Chrome"
            if not (exists front window) then return ""
            return URL of active tab of front window
        end tell
        """)
  }

  func activeTabURL() throws -> URL {
    guard let script else {
      throw BrowserContextError.scriptCreationFailed
    }

    var errorInfo: NSDictionary?
    let descriptor = script.executeAndReturnError(&errorInfo)
    if let errorInfo {
      let code = errorInfo[NSAppleScript.errorNumber] as? Int
      let message =
        errorInfo[NSAppleScript.errorMessage] as? String
        ?? "Unknown Apple Event error"
      throw BrowserContextError.executionFailed(code: code, message: message)
    }

    guard let value = descriptor.stringValue, !value.isEmpty else {
      throw BrowserContextError.emptyURL
    }
    guard let url = URL(string: value) else {
      throw BrowserContextError.malformedURL
    }
    return url
  }
}

final class ForegroundApplicationProvider: ForegroundApplicationProviding {
  private let ownBundleIdentifier: String?
  private var lastExternalApplication: NSRunningApplication?
  private var observer: NSObjectProtocol?

  init(ownBundleIdentifier: String? = Bundle.main.bundleIdentifier) {
    self.ownBundleIdentifier = ownBundleIdentifier

    let current = NSWorkspace.shared.frontmostApplication
    if current?.bundleIdentifier != ownBundleIdentifier {
      lastExternalApplication = current
    }

    observer = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let self,
        let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
          as? NSRunningApplication,
        application.bundleIdentifier != self.ownBundleIdentifier
      else {
        return
      }
      self.lastExternalApplication = application
    }
  }

  func foregroundApplication() -> ApplicationSnapshot? {
    let current = NSWorkspace.shared.frontmostApplication
    if current?.bundleIdentifier != ownBundleIdentifier {
      lastExternalApplication = current
      return current.map(Self.snapshot)
    }
    return lastExternalApplication.map(Self.snapshot)
  }

  func isStillForeground(_ application: ApplicationSnapshot) -> Bool {
    NSWorkspace.shared.frontmostApplication?.processIdentifier
      == application.processIdentifier
  }

  func isPotentialQuickDrawTargetForeground() -> Bool {
    guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
      return false
    }
    return ActionCatalog.target(forBundleIdentifier: bundleIdentifier) != nil
  }

  private static func snapshot(_ application: NSRunningApplication) -> ApplicationSnapshot {
    ApplicationSnapshot(
      processIdentifier: application.processIdentifier,
      bundleIdentifier: application.bundleIdentifier
    )
  }

  deinit {
    if let observer {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
  }
}
