import AppKit

final class StatusMenuController: NSObject {
  var onToggleEnabled: ((Bool) -> Void)?
  var onToggleDryRun: ((Bool) -> Void)?
  var onRunDryCheck: (() -> Void)?
  var onRequestAccessibility: (() -> Void)?
  var onCopyDiagnostics: (() -> String)?

  private let statusItem: NSStatusItem
  private let enabledItem = NSMenuItem()
  private let dryRunItem = NSMenuItem()
  private let headlineItem = NSMenuItem()
  private let detailItem = NSMenuItem()
  private let targetItem = NSMenuItem()
  private let permissionStatusItem = NSMenuItem()
  private let permissionActionItem = NSMenuItem()
  private let feedbackPopover = NSPopover()
  private let feedbackHeadline = NSTextField(labelWithString: "")
  private let feedbackDetail = NSTextField(labelWithString: "")
  private let feedbackTarget = NSTextField(labelWithString: "")

  override init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    super.init()

    configureFeedbackPopover()

    if let button = statusItem.button {
      button.image = NSImage(
        systemSymbolName: "speaker.slash.circle",
        accessibilityDescription: "QuickDraw PoC"
      )
      button.toolTip = "QuickDraw PoC — F6 to Mute"
    }

    let menu = NSMenu()
    addDisabledItem("QuickDraw PoC — F6 to Mute", to: menu)

    headlineItem.title = "Starting…"
    headlineItem.isEnabled = false
    menu.addItem(headlineItem)

    detailItem.isEnabled = false
    menu.addItem(detailItem)

    targetItem.title = "Target: Not detected"
    targetItem.isEnabled = false
    menu.addItem(targetItem)

    permissionStatusItem.title = "Accessibility: Checking…"
    permissionStatusItem.isEnabled = false
    menu.addItem(permissionStatusItem)

    menu.addItem(.separator())

    enabledItem.title = "Enabled"
    enabledItem.state = .on
    enabledItem.target = self
    enabledItem.action = #selector(toggleEnabled(_:))
    menu.addItem(enabledItem)

    dryRunItem.title = "Dry Run (F6 does not send keys)"
    dryRunItem.state = .off
    dryRunItem.target = self
    dryRunItem.action = #selector(toggleDryRun(_:))
    menu.addItem(dryRunItem)

    let dryCheckItem = NSMenuItem(
      title: "Run Dry Check on Last Active App",
      action: #selector(runDryCheck),
      keyEquivalent: ""
    )
    dryCheckItem.target = self
    menu.addItem(dryCheckItem)

    permissionActionItem.title = "Request Accessibility Permission…"
    permissionActionItem.target = self
    permissionActionItem.action = #selector(requestAccessibility)
    menu.addItem(permissionActionItem)

    menu.addItem(.separator())

    let copyItem = NSMenuItem(
      title: "Copy Diagnostics",
      action: #selector(copyDiagnostics),
      keyEquivalent: ""
    )
    copyItem.target = self
    menu.addItem(copyItem)

    addDisabledItem("Hotkey: F6 Registered", to: menu)
    addDisabledItem("Privacy: Meet classification only; no key logging", to: menu)

    menu.addItem(.separator())

    let quitItem = NSMenuItem(
      title: "Quit QuickDraw PoC",
      action: #selector(quit),
      keyEquivalent: "q"
    )
    quitItem.target = self
    menu.addItem(quitItem)

    statusItem.menu = menu
  }

  func update(status: MuteStatus, hasAccessibilityPermission: Bool) {
    headlineItem.title = status.headline
    detailItem.title = status.detail
    targetItem.title = "Target: \(status.target)"
    permissionStatusItem.title =
      hasAccessibilityPermission
      ? "Accessibility: Granted"
      : "Accessibility: Required"
    permissionActionItem.isHidden = hasAccessibilityPermission
    feedbackHeadline.stringValue = status.headline
    feedbackDetail.stringValue = status.detail
    feedbackTarget.stringValue = "Target: \(status.target)"

    statusItem.button?.image = NSImage(
      systemSymbolName: status.isError ? "exclamationmark.circle" : "speaker.slash.circle",
      accessibilityDescription: status.headline
    )
  }

  func setEnabled(_ enabled: Bool) {
    enabledItem.state = enabled ? .on : .off
  }

  func setDryRun(_ enabled: Bool) {
    dryRunItem.state = enabled ? .on : .off
  }

  private func addDisabledItem(_ title: String, to menu: NSMenu) {
    let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
    item.isEnabled = false
    menu.addItem(item)
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

  @objc private func requestAccessibility() {
    onRequestAccessibility?()
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
