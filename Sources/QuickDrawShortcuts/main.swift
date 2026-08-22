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
    subsystem: Bundle.main.bundleIdentifier ?? "com.keishingu.rinvio",
    category: "lifecycle"
  )

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApplication.shared.setActivationPolicy(.regular)
    RinvioDefaultsMigration.migrateIfNeeded()

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
      let permissions = controller.permissionState
      menuController?.update(
        status: status,
        permissions: permissions
      )
      model?.update(
        status: status,
        permissions: permissions,
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
    model.onRequestInputMonitoring = { [weak controller] in
      controller?.requestInputMonitoringAccess()
    }
    model.onRequestPostEvent = { [weak controller] in
      controller?.requestPostEventAccess()
    }
    model.onRefreshPermissions = { [weak controller, weak coordinator, weak model] in
      guard let controller else {
        return KeyboardPermissionState(
          hasInputMonitoringAccess: false,
          hasPostEventAccess: false
        )
      }
      let permissions = controller.permissionState
      if permissions.canMonitorTriggers, !controller.areHotKeysRegistered {
        coordinator?.setRegistrationAllowed(true)
        let error = coordinator?.resume()
        let registered = error == nil
        controller.areHotKeysRegistered = registered
        model?.setHotKeysRegistered(registered)
      } else if !permissions.canMonitorTriggers, controller.areHotKeysRegistered {
        coordinator?.setRegistrationAllowed(false)
        controller.areHotKeysRegistered = false
        model?.setHotKeysRegistered(false)
      } else if !permissions.canMonitorTriggers {
        coordinator?.setRegistrationAllowed(false)
      }
      return permissions
    }
    model.onRefreshDiagnostics = { [weak controller] in
      controller?.diagnosticsText() ?? "Rinvio Diagnostics unavailable"
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
      let hasPermission = controller?.hasInputMonitoringAccess == true
      coordinator?.setRegistrationAllowed(hasPermission)
      let error = hasPermission ? coordinator?.resume() : "Input Monitoring permission is required"
      cheatSheetController?.isSuppressed = false
      let registered = hasPermission && error == nil
      controller?.areHotKeysRegistered = registered
      model?.setHotKeysRegistered(registered)
      return error
    }
    model.onApplyTrigger = { [weak coordinator, weak controller, weak model] action, shortcut in
      let error = coordinator?.applyTrigger(shortcut, for: action)
      let registered = controller?.hasInputMonitoringAccess == true && error == nil
      controller?.areHotKeysRegistered = registered
      model?.setHotKeysRegistered(registered)
      updateTriggerPresentation()
      return error
    }
    model.onResetTrigger = { [weak coordinator, weak controller, weak model] action in
      let error = coordinator?.resetTrigger(for: action)
      let registered = controller?.hasInputMonitoringAccess == true && error == nil
      controller?.areHotKeysRegistered = registered
      model?.setHotKeysRegistered(registered)
      updateTriggerPresentation()
      return error
    }
    model.onUnassignTrigger = { [weak coordinator, weak controller, weak model] action in
      let error = coordinator?.unassignTrigger(for: action)
      let registered = controller?.hasInputMonitoringAccess == true && error == nil
      controller?.areHotKeysRegistered = registered
      model?.setHotKeysRegistered(registered)
      updateTriggerPresentation()
      return error
    }
    model.onResetAction = { [weak coordinator, weak controller, weak model] action in
      let error = coordinator?.resetAction(action)
      let registered = controller?.hasInputMonitoringAccess == true && error == nil
      controller?.areHotKeysRegistered = registered
      model?.setHotKeysRegistered(registered)
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
      let registered = controller?.hasInputMonitoringAccess == true && result.error == nil
      controller?.areHotKeysRegistered = registered
      model?.setHotKeysRegistered(registered)
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
    menuController.onRequestInputMonitoring = { [weak model] in
      model?.requestInputMonitoring()
    }
    menuController.onRequestPostEvent = { [weak model] in
      model?.requestPostEvent()
    }
    menuController.onCopyDiagnostics = { [weak controller] in
      controller?.diagnosticsText() ?? "Rinvio Diagnostics unavailable"
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
      [weak foregroundProvider, weak activeTabProvider, weak model, weak windowController] in
      guard
        let bundleIdentifier = foregroundProvider?.foregroundApplication()?.bundleIdentifier,
        let foregroundTarget = ActionCatalog.target(forBundleIdentifier: bundleIdentifier)
      else {
        NSSound.beep()
        return
      }
      var target = foregroundTarget
      if foregroundTarget == .googleChrome,
        let activeTabProvider,
        let activeTabURL = try? activeTabProvider.activeTabURL(),
        let webApplication = ActionCatalog.webApplication(
          in: foregroundTarget,
          matching: activeTabURL
        )
      {
        target = webApplication.target
      }
      model?.openApplicationSettings(for: target)
      windowController?.present()
    }

    coordinator.prepare(
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

    coordinator.setRegistrationAllowed(controller.hasInputMonitoringAccess)

    let registrationError =
      controller.hasInputMonitoringAccess
      ? coordinator.resume()
      : "Input Monitoring permission is required"
    let registered = registrationError == nil
    controller.areHotKeysRegistered = registered
    model.setHotKeysRegistered(registered)
    let permissions = controller.permissionState
    let initialHeadline: String
    if !permissions.hasInputMonitoringAccess {
      initialHeadline = "Input Monitoring required"
    } else if registrationError != nil {
      initialHeadline = "Global shortcut registration failed"
    } else {
      initialHeadline = "Enabled — shortcuts ready"
    }
    let initialStatus = ActionStatus(
      action: nil,
      headline: initialHeadline,
      detail: registrationError ?? controller.permissionSummary,
      target: "Not detected",
      isError: registrationError != nil || !permissions.isFullyAuthorized
    )
    menuController.update(status: initialStatus, permissions: permissions)
    model.update(
      status: initialStatus,
      permissions: permissions,
      diagnostics: controller.diagnosticsText()
    )
    if let registrationError {
      logger.error(
        "Rinvio started without hotkey reason=\(registrationError, privacy: .public)"
      )
    } else {
      logger.info(
        "Rinvio started hotkeys=\(controller.triggerSummary, privacy: .public) inputMonitoringAccess=\(permissions.hasInputMonitoringAccess, privacy: .public) postEventAccess=\(permissions.hasPostEventAccess, privacy: .public)"
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
