import AppKit
import OSLog
import QuickDrawCore

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var hotKeyRegistrar: GlobalHotKeyRegistrar?
  private var muteController: MuteController?
  private var statusMenuController: StatusMenuController?
  private var configurationWindowController: ConfigurationWindowController?
  private var appModel: QuickDrawAppModel?
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
    let model = QuickDrawAppModel()
    let windowController = ConfigurationWindowController(model: model)
    menuController.setLanguage(model.language)

    controller.onStatusChange = { [weak controller, weak menuController, weak model] status in
      guard let controller else { return }
      menuController?.update(
        status: status,
        hasAccessibilityPermission: controller.hasPostEventAccess
      )
      model?.update(
        status: status,
        hasAccessibilityPermission: controller.hasPostEventAccess,
        diagnostics: controller.diagnosticsText()
      )
    }
    model.onSetEnabled = { [weak controller, weak menuController] enabled in
      controller?.isEnabled = enabled
      menuController?.setEnabled(enabled)
    }
    model.onSetDryRun = { [weak controller, weak menuController] enabled in
      controller?.isDryRunEnabled = enabled
      menuController?.setDryRun(enabled)
    }
    model.onRunDryCheck = { [weak controller] in
      controller?.triggerMute(forceDryRun: true)
    }
    model.onRequestAccessibility = { [weak controller] in
      controller?.requestPostEventAccess()
    }
    model.onRefreshPermission = { [weak controller] in
      controller?.hasPostEventAccess ?? false
    }
    model.onRefreshDiagnostics = { [weak controller] in
      controller?.diagnosticsText() ?? "QuickDraw Diagnostics unavailable"
    }
    model.onLanguageChange = { [weak menuController] language in
      menuController?.setLanguage(language)
    }

    menuController.onToggleEnabled = { [weak model] enabled in
      model?.setEnabled(enabled)
    }
    menuController.onToggleDryRun = { [weak model] enabled in
      model?.setDryRunEnabled(enabled)
    }
    menuController.onOpenWindow = { [weak windowController, weak model] in
      model?.refreshEnvironment()
      windowController?.present()
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
      model.setHotKeyRegistered(true)
      let initialStatus = MuteStatus(
        headline: "Enabled — press F6",
        detail: controller.permissionSummary,
        target: "Not detected",
        isError: !shortcutExecutor.hasPostEventAccess
      )
      menuController.update(
        status: initialStatus,
        hasAccessibilityPermission: shortcutExecutor.hasPostEventAccess
      )
      model.update(
        status: initialStatus,
        hasAccessibilityPermission: shortcutExecutor.hasPostEventAccess,
        diagnostics: controller.diagnosticsText()
      )
      logger.info(
        "QuickDraw PoC started hotkey=F6 postEventAccess=\(shortcutExecutor.hasPostEventAccess, privacy: .public)"
      )
    } catch {
      controller.isEnabled = false
      model.setHotKeyRegistered(false)
      model.setEnabled(false)
      let failureStatus = MuteStatus(
        headline: "F6 registration failed",
        detail: error.localizedDescription,
        target: "Not detected",
        isError: true
      )
      menuController.update(
        status: failureStatus,
        hasAccessibilityPermission: shortcutExecutor.hasPostEventAccess
      )
      model.update(
        status: failureStatus,
        hasAccessibilityPermission: shortcutExecutor.hasPostEventAccess,
        diagnostics: controller.diagnosticsText()
      )
      logger.error(
        "QuickDraw PoC started without hotkey reason=\(error.localizedDescription, privacy: .public)"
      )
    }

    hotKeyRegistrar = registrar
    muteController = controller
    statusMenuController = menuController
    configurationWindowController = windowController
    appModel = model

    windowController.present()
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    appModel?.refreshEnvironment()
  }
}

let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.run()
