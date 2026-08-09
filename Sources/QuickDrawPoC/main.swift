import AppKit
import OSLog
import QuickDrawCore

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var hotKeyRegistrar: GlobalHotKeyRegistrar?
  private var actionController: ActionController?
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
    let pipeline = ActionPipeline(
      applicationProvider: foregroundProvider,
      activeTabProvider: ChromeActiveTabProvider(),
      shortcutDeliverer: shortcutExecutor
    )
    let controller = ActionController(
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
    model.onRunDryCheck = { [weak controller] action in
      controller?.trigger(action, forceDryRun: true)
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
      controller?.trigger(.mute, forceDryRun: true)
    }
    menuController.onRequestAccessibility = { [weak controller] in
      controller?.requestPostEventAccess()
    }
    menuController.onCopyDiagnostics = { [weak controller] in
      controller?.diagnosticsText() ?? "QuickDraw PoC Diagnostics unavailable"
    }

    let registrar = GlobalHotKeyRegistrar()
    do {
      try registrar.registerDefaultActions { [weak controller] action in
        controller?.trigger(action)
      }
      controller.areHotKeysRegistered = true
      model.setHotKeysRegistered(true)
      let initialStatus = ActionStatus(
        action: nil,
        headline: "Enabled — F6/F7/F8 ready",
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
        "QuickDraw PoC started hotkeys=F6,F7,F8 postEventAccess=\(shortcutExecutor.hasPostEventAccess, privacy: .public)"
      )
    } catch {
      controller.isEnabled = false
      model.setHotKeysRegistered(false)
      model.setEnabled(false)
      let failureStatus = ActionStatus(
        action: nil,
        headline: "Global shortcut registration failed",
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
    actionController = controller
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
