import AppKit

final class StatusMenuController: NSObject {
  var onToggleEnabled: ((Bool) -> Void)?
  var onToggleDryRun: ((Bool) -> Void)?
  var onOpenWindow: (() -> Void)?
  var onRunDryCheck: (() -> Void)?
  var onRequestInputMonitoring: (() -> Void)?
  var onRequestPostEvent: (() -> Void)?
  var onCopyDiagnostics: (() -> String)?

  private let statusItem: NSStatusItem
  private let enabledItem = NSMenuItem()
  private let dryRunItem = NSMenuItem()
  private let headlineItem = NSMenuItem()
  private let detailItem = NSMenuItem()
  private let targetItem = NSMenuItem()
  private let inputMonitoringStatusItem = NSMenuItem()
  private let postEventStatusItem = NSMenuItem()
  private let inputMonitoringActionItem = NSMenuItem()
  private let postEventActionItem = NSMenuItem()
  private let appTitleItem = NSMenuItem()
  private let openItem = NSMenuItem()
  private let dryCheckItem = NSMenuItem()
  private let copyItem = NSMenuItem()
  private let hotKeyItem = NSMenuItem()
  private let privacyItem = NSMenuItem()
  private let developerSectionSeparator = NSMenuItem.separator()
  private let quitItem = NSMenuItem()
  private let feedbackPopover = NSPopover()
  private let feedbackHeadline = NSTextField(labelWithString: "")
  private let feedbackDetail = NSTextField(labelWithString: "")
  private let feedbackTarget = NSTextField(labelWithString: "")
  private var language: AppLanguage = .english
  private var lastStatus = ActionStatus(
    action: nil,
    headline: "Starting…",
    detail: "Preparing shortcuts",
    target: "Not detected",
    isError: false
  )
  private var lastPermissions = KeyboardPermissionState(
    hasInputMonitoringAccess: false,
    hasPostEventAccess: false
  )
  private var triggerCount = 0

  override init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    super.init()

    configureFeedbackPopover()

    if let button = statusItem.button {
      button.image = Self.quickDrawStatusImage()
      button.setAccessibilityLabel(applicationDisplayName)
    }

    let menu = NSMenu()
    configureDisabledItem(appTitleItem)
    menu.addItem(appTitleItem)

    headlineItem.isEnabled = false
    menu.addItem(headlineItem)

    detailItem.isEnabled = false
    menu.addItem(detailItem)

    targetItem.isEnabled = false
    menu.addItem(targetItem)

    inputMonitoringStatusItem.isEnabled = false
    menu.addItem(inputMonitoringStatusItem)

    postEventStatusItem.isEnabled = false
    menu.addItem(postEventStatusItem)

    menu.addItem(.separator())

    openItem.action = #selector(openWindow)
    openItem.target = self
    menu.addItem(openItem)

    menu.addItem(.separator())

    enabledItem.state = .on
    enabledItem.target = self
    enabledItem.action = #selector(toggleEnabled(_:))
    menu.addItem(enabledItem)

    dryRunItem.state = .off
    dryRunItem.target = self
    dryRunItem.action = #selector(toggleDryRun(_:))
    menu.addItem(dryRunItem)

    dryCheckItem.action = #selector(runDryCheck)
    dryCheckItem.target = self
    menu.addItem(dryCheckItem)

    inputMonitoringActionItem.target = self
    inputMonitoringActionItem.action = #selector(requestInputMonitoring)
    menu.addItem(inputMonitoringActionItem)

    postEventActionItem.target = self
    postEventActionItem.action = #selector(requestPostEvent)
    menu.addItem(postEventActionItem)

    menu.addItem(developerSectionSeparator)

    copyItem.action = #selector(copyDiagnostics)
    copyItem.target = self
    menu.addItem(copyItem)

    configureDisabledItem(hotKeyItem)
    menu.addItem(hotKeyItem)
    configureDisabledItem(privacyItem)
    menu.addItem(privacyItem)

    menu.addItem(.separator())

    quitItem.action = #selector(quit)
    quitItem.keyEquivalent = "q"
    quitItem.target = self
    menu.addItem(quitItem)

    statusItem.menu = menu
    setDeveloperMode(false)
    applyLanguage()
  }

  func update(status: ActionStatus, permissions: KeyboardPermissionState) {
    lastStatus = status
    lastPermissions = permissions
    let copy = QuickDrawCopy(language: language)
    let localizedStatus = copy.localizedStatus(status)

    headlineItem.title = localizedStatus.headline
    detailItem.title = localizedStatus.detail
    targetItem.title = "\(copy.targetPrefix): \(localizedStatus.target)"
    inputMonitoringStatusItem.title =
      permissions.hasInputMonitoringAccess
      ? copy.inputMonitoringGrantedMenu
      : copy.inputMonitoringRequiredMenu
    postEventStatusItem.title =
      permissions.hasPostEventAccess
      ? copy.shortcutDeliveryGrantedMenu
      : copy.shortcutDeliveryRequiredMenu
    inputMonitoringActionItem.isHidden = permissions.hasInputMonitoringAccess
    postEventActionItem.isHidden = permissions.hasPostEventAccess
    feedbackHeadline.stringValue = localizedStatus.headline
    feedbackDetail.stringValue = localizedStatus.detail
    feedbackTarget.stringValue = "\(copy.targetPrefix): \(localizedStatus.target)"

    statusItem.button?.image =
      status.isError
      ? NSImage(
        systemSymbolName: "exclamationmark.circle",
        accessibilityDescription: localizedStatus.headline
      )
      : Self.quickDrawStatusImage()
    statusItem.button?.setAccessibilityLabel(localizedStatus.headline)
  }

  func setLanguage(_ language: AppLanguage) {
    self.language = language
    applyLanguage()
    update(
      status: lastStatus,
      permissions: lastPermissions
    )
  }

  func setEnabled(_ enabled: Bool) {
    enabledItem.state = enabled ? .on : .off
  }

  func setDryRun(_ enabled: Bool) {
    dryRunItem.state = enabled ? .on : .off
  }

  func setDeveloperMode(_ enabled: Bool) {
    dryRunItem.isHidden = !enabled
    dryCheckItem.isHidden = !enabled
    developerSectionSeparator.isHidden = !enabled
    copyItem.isHidden = !enabled
    hotKeyItem.isHidden = !enabled
    privacyItem.isHidden = !enabled
  }

  func setTriggerCount(_ count: Int) {
    triggerCount = count
    applyLanguage()
  }

  private func configureDisabledItem(_ item: NSMenuItem) {
    item.isEnabled = false
  }

  private static func quickDrawStatusImage() -> NSImage? {
    guard let image = NSImage(named: "StatusBarIcon") else {
      return NSImage(
        systemSymbolName: "link",
        accessibilityDescription: "Rinvio"
      )
    }
    image.isTemplate = true
    image.size = NSSize(width: 18, height: 18)
    return image
  }

  private func applyLanguage() {
    let copy = QuickDrawCopy(language: language)
    statusItem.button?.toolTip = copy.menuTitle
    appTitleItem.title = copy.menuTitle
    openItem.title = copy.openQuickDraw
    enabledItem.title = copy.enabled
    dryRunItem.title = copy.dryRunMenu
    dryCheckItem.title = copy.runDryCheckMenu
    inputMonitoringActionItem.title = copy.requestInputMonitoringMenu
    postEventActionItem.title = copy.requestShortcutDeliveryMenu
    copyItem.title = copy.copyDiagnostics
    hotKeyItem.title = copy.hotKeyRegisteredMenu(triggerCount)
    privacyItem.title = copy.privacyMenu
    quitItem.title = copy.quitQuickDraw
  }

  private func configureFeedbackPopover() {
    feedbackPopover.behavior = .transient
    feedbackPopover.animates = true

    feedbackHeadline.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
    feedbackDetail.textColor = .secondaryLabelColor
    feedbackTarget.textColor = .secondaryLabelColor

    let stack = NSStackView(views: [feedbackHeadline, feedbackDetail, feedbackTarget])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 5
    stack.translatesAutoresizingMaskIntoConstraints = false

    let container = NSView()
    container.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
      stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
      stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
    ])

    let viewController = NSViewController()
    viewController.view = container
    feedbackPopover.contentViewController = viewController
    feedbackPopover.contentSize = NSSize(width: 300, height: 96)
  }

  private func showFeedbackPopover() {
    guard let button = statusItem.button else {
      return
    }
    feedbackPopover.show(
      relativeTo: button.bounds,
      of: button,
      preferredEdge: .minY
    )
  }

  @objc private func toggleEnabled(_ sender: NSMenuItem) {
    let enabled = sender.state != .on
    sender.state = enabled ? .on : .off
    onToggleEnabled?(enabled)
  }

  @objc private func openWindow() {
    onOpenWindow?()
  }

  @objc private func toggleDryRun(_ sender: NSMenuItem) {
    let enabled = sender.state != .on
    sender.state = enabled ? .on : .off
    onToggleDryRun?(enabled)
  }

  @objc private func runDryCheck() {
    onRunDryCheck?()
    DispatchQueue.main.async { [weak self] in
      self?.showFeedbackPopover()
    }
  }

  @objc private func requestInputMonitoring() {
    onRequestInputMonitoring?()
  }

  @objc private func requestPostEvent() {
    onRequestPostEvent?()
  }

  @objc private func copyDiagnostics() {
    guard let diagnostics = onCopyDiagnostics?() else {
      return
    }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(diagnostics, forType: .string)
  }

  @objc private func quit() {
    NSApplication.shared.terminate(nil)
  }
}
