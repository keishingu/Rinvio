import AppKit
import OSLog
import QuickDrawCore

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var hotKeyRegistrar: GlobalHotKeyRegistrar?
  private var muteController: MuteController?
  private var statusMenuController: StatusMenuController?
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.actionrouter.quickdraw-poc",
    category: "lifecycle"
  )

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApplication.shared.setActivationPolicy(.accessory)

    let foregroundProvider = ForegroundApplicationProvider()
    let shortcutExecutor = ShortcutExecutor()
    let pipeline = MutePipeline(
      applicationProvider: foregroundProvider,
      activeTabProvider: ChromeActiveTabProvider(),
      shortcutDeliverer: shortcutExecutor
    )
    let controller = MuteController(
      pipeline: pipeline,
      shortcutExecutor: shortcutExecutor
    )
    let menuController = StatusMenuController()

    controller.onStatusChange = { [weak controller, weak menuController] status in
      guard let controller else { return }
      menuController?.update(
        status: status,
        hasAccessibilityPermission: controller.hasPostEventAccess
      )
    }
    menuController.onToggleEnabled = { [weak controller] enabled in
      controller?.isEnabled = enabled
    }
    menuController.onToggleDryRun = { [weak controller] enabled in
      controller?.isDryRunEnabled = enabled
    }
    menuController.onRunDryCheck = { [weak controller] in
      controller?.triggerMute(forceDryRun: true)
    }
    menuController.onRequestAccessibility = { [weak controller] in
      controller?.requestPostEventAccess()
    }
    menuController.onCopyDiagnostics = { [weak controller] in
      controller?.diagnosticsText() ?? "QuickDraw PoC Diagnostics unavailable"
    }

    let registrar = GlobalHotKeyRegistrar()
    do {
      try registrar.registerF6 { [weak controller] in
        controller?.triggerMute()
      }
      controller.isHotKeyRegistered = true
      menuController.update(
        status: MuteStatus(
          headline: "Enabled — press F6",
          detail: controller.permissionSummary,
          target: "Not detected",
          isError: !shortcutExecutor.hasPostEventAccess
        ),
        hasAccessibilityPermission: shortcutExecutor.hasPostEventAccess
      )
      logger.info(
        "QuickDraw PoC started hotkey=F6 postEventAccess=\(shortcutExecutor.hasPostEventAccess, privacy: .public)"
      )
    } catch {
      controller.isEnabled = false
      menuController.setEnabled(false)
      menuController.update(
        status: MuteStatus(
          headline: "F6 registration failed",
          detail: error.localizedDescription,
          target: "Not detected",
          isError: true
        ),
        hasAccessibilityPermission: shortcutExecutor.hasPostEventAccess
      )
      logger.error(
        "QuickDraw PoC started without hotkey reason=\(error.localizedDescription, privacy: .public)"
      )
    }

    hotKeyRegistrar = registrar
    muteController = controller
    statusMenuController = menuController
  }
}

let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.run()
