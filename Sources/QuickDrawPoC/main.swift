import AppKit
import OSLog
import QuickDrawCore

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var hotKeyCoordinator: HotKeyConfigurationCoordinator?
  private var actionController: ActionController?
  private var statusMenuController: StatusMenuController?
  private var applicationMenuController: ApplicationMenuController?
  private var configurationWindowController: ConfigurationWindowController?
  private var shortcutCheatSheetController: ShortcutCheatSheetController?
  private var appModel: QuickDrawAppModel?
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.actionrouter.quickdraw-poc",
    category: "lifecycle"
  )

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApplication.shared.setActivationPolicy(.regular)

    let configurationStore = QuickDrawConfigurationStore()
    let foregroundProvider = ForegroundApplicationProvider()
    let activeTabProvider = ChromeActiveTabProvider()
    let shortcutExecutor = ShortcutExecutor()
    let pipeline = ActionPipeline(
      router: ActionRouter(
        overrideProvider: configurationStore,
        applicationEnablementProvider: configurationStore
      ),
      applicationProvider: foregroundProvider,
      activeTabProvider: activeTabProvider,
      shortcutDeliverer: shortcutExecutor
    )
    let controller = ActionController(
      pipeline: pipeline,
      shortcutExecutor: shortcutExecutor
    )
    let menuController = StatusMenuController()
    let applicationMenuController = ApplicationMenuController()
    let model = QuickDrawAppModel(configurationStore: configurationStore)
    let cheatSheetController = ShortcutCheatSheetController(
      configurationStore: configurationStore,
      foregroundProvider: foregroundProvider,
      activeTabProvider: activeTabProvider,
      languageProvider: { [weak model] in model?.language ?? .english }
    )
    cheatSheetController.isCheatSheetEnabled = model.isCheatSheetEnabled
    let windowController = ConfigurationWindowController(model: model)
    let coordinator = HotKeyConfigurationCoordinator(
      registrar: GlobalHotKeyRegistrar(),
      store: configurationStore
    )
    menuController.setLanguage(model.language)
    menuController.setDeveloperMode(model.isDeveloperModeEnabled)
    applicationMenuController.setLanguage(model.language)
    applicationMenuController.install()

    let updateTriggerPresentation = {
      let triggers = Action.allCases.compactMap { action -> String? in
        if ActionCatalog.isSystemWide(action) { return nil }
        return configurationStore.trigger(for: action)?.displayValue
      }
      controller.triggerSummary = triggers.joined(separator: "/")
      menuController.setTriggerCount(triggers.count)
    }
    updateTriggerPresentation()

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
    model.onSetEnabled = {
      [
        weak controller, weak menuController, weak applicationMenuController,
        weak cheatSheetController
      ] enabled in
      controller?.isEnabled = enabled
      menuController?.setEnabled(enabled)
      applicationMenuController?.setEnabled(enabled)
      cheatSheetController?.isQuickDrawEnabled = enabled
    }
    model.onSetDryRun = { [weak controller, weak menuController] enabled in
      controller?.isDryRunEnabled = enabled
      menuController?.setDryRun(enabled)
    }
    model.onSetCheatSheetEnabled = { [weak cheatSheetController] enabled in
      cheatSheetController?.isCheatSheetEnabled = enabled
    }
    model.onSetDeveloperMode = { [weak menuController] enabled in
      menuController?.setDeveloperMode(enabled)
    }
    model.onPreviewCheatSheet = { [weak cheatSheetController] in
      cheatSheetController?.presentPreview()
    }
    model.onRunDryCheck = { [weak controller] action in
      controller?.trigger(action, forceDryRun: true)
    }
    model.onRequestAccessibility = { [weak controller] in
      controller?.requestPostEventAccess()
    }
    model.onRefreshPermission = { [weak controller, weak coordinator, weak model] in
      guard let controller else { return false }
      let granted = controller.hasPostEventAccess
      if granted, !controller.areHotKeysRegistered {
        let error = coordinator?.resume()
        let registered = error == nil
        controller.areHotKeysRegistered = registered
        model?.setHotKeysRegistered(registered)
        if registered {
          model?.setEnabled(true)
        }
      }
      return granted
    }
    model.onRefreshDiagnostics = { [weak controller] in
      controller?.diagnosticsText() ?? "QuickDraw Diagnostics unavailable"
    }
    model.onLanguageChange = { [weak menuController, weak applicationMenuController] language in
      menuController?.setLanguage(language)
      applicationMenuController?.setLanguage(language)
    }
    model.onShortcutRecordingBegan = {
      [weak coordinator, weak controller, weak model, weak cheatSheetController] in
      cheatSheetController?.isSuppressed = true
      coordinator?.suspend()
      controller?.areHotKeysRegistered = false
      model?.setHotKeysRegistered(false)
    }
    model.onShortcutRecordingEnded = {
      [weak coordinator, weak controller, weak model, weak cheatSheetController] in
      let error = coordinator?.resume()
      cheatSheetController?.isSuppressed = false
      controller?.areHotKeysRegistered = error == nil
      model?.setHotKeysRegistered(error == nil)
      return error
    }
    model.onApplyTrigger = { [weak coordinator, weak controller, weak model] action, shortcut in
      let error = coordinator?.applyTrigger(shortcut, for: action)
      controller?.areHotKeysRegistered = error == nil
      model?.setHotKeysRegistered(error == nil)
      updateTriggerPresentation()
      return error
    }
    model.onResetTrigger = { [weak coordinator, weak controller, weak model] action in
      let error = coordinator?.resetTrigger(for: action)
      controller?.areHotKeysRegistered = error == nil
      model?.setHotKeysRegistered(error == nil)
      updateTriggerPresentation()
      return error
    }
    model.onUnassignTrigger = { [weak coordinator, weak controller, weak model] action in
      let error = coordinator?.unassignTrigger(for: action)
      controller?.areHotKeysRegistered = error == nil
      model?.setHotKeysRegistered(error == nil)
      updateTriggerPresentation()
      return error
    }
    model.onResetAction = { [weak coordinator, weak controller, weak model] action in
      let error = coordinator?.resetAction(action)
      controller?.areHotKeysRegistered = error == nil
      model?.setHotKeysRegistered(error == nil)
      updateTriggerPresentation()
      return error
    }
    model.onAlignDevelopmentTriggers = {
      [weak coordinator, weak controller, weak model] target in
      let result =
        coordinator?.alignDevelopmentTriggers(to: target)
        ?? TriggerAlignmentResult(
          appliedCount: 0,
          skippedDuplicateCount: 0,
          error: "Global shortcut handler is unavailable"
        )
      controller?.areHotKeysRegistered = result.error == nil
      model?.setHotKeysRegistered(result.error == nil)
      updateTriggerPresentation()
      return result
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
    applicationMenuController.onSelectSection = { [weak model, weak windowController] section in
      model?.selectSection(section)
      windowController?.present()
    }
    applicationMenuController.onShowShortcutGuide = { [weak model] in
      model?.previewCheatSheet()
    }
    applicationMenuController.onToggleEnabled = { [weak model] in
      guard let model else { return }
      model.setEnabled(!model.isEnabled)
    }
    applicationMenuController.onOpenLastApplicationSettings = {
      [weak foregroundProvider, weak model, weak windowController] in
      guard
        let bundleIdentifier = foregroundProvider?.foregroundApplication()?.bundleIdentifier,
        let target = ActionCatalog.target(forBundleIdentifier: bundleIdentifier)
      else {
        NSSound.beep()
        return
      }
      model?.openApplicationSettings(for: target)
      windowController?.present()
    }

    do {
      try coordinator.start(
        handler: {
          [weak controller, weak foregroundProvider, weak cheatSheetController] actions in
          guard foregroundProvider?.isPotentialQuickDrawTargetForeground() == true else {
            return false
          }
          let wasHandled = controller?.trigger(actions) ?? false
          if wasHandled {
            DispatchQueue.main.async {
              cheatSheetController?.handleShortcutExecution()
            }
          }
          return wasHandled
        },
        modifierHandler: { [weak cheatSheetController] modifiers in
          DispatchQueue.main.async {
            cheatSheetController?.handleModifierChange(modifiers)
          }
        },
        nonModifierKeyHandler: { [weak cheatSheetController] in
          cheatSheetController?.handleNonModifierKeyPress()
        }
      )
      controller.areHotKeysRegistered = true
      model.setHotKeysRegistered(true)
      let initialStatus = ActionStatus(
        action: nil,
        headline: "Enabled — shortcuts ready",
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
        "QuickDraw PoC started hotkeys=\(controller.triggerSummary, privacy: .public) postEventAccess=\(shortcutExecutor.hasPostEventAccess, privacy: .public)"
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

    hotKeyCoordinator = coordinator
    actionController = controller
    statusMenuController = menuController
    self.applicationMenuController = applicationMenuController
    configurationWindowController = windowController
    shortcutCheatSheetController = cheatSheetController
    appModel = model

    windowController.present()
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    appModel?.refreshEnvironment()
  }

  func applicationDidResignActive(_ notification: Notification) {
    appModel?.cancelRecording()
  }

  func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag {
      configurationWindowController?.present()
    }
    return true
  }
}

let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.run()
