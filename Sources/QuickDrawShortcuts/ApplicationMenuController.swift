import AppKit

@MainActor
final class ApplicationMenuController: NSObject {
  var onSelectSection: ((QuickDrawSection) -> Void)?
  var onShowShortcutGuide: (() -> Void)?
  var onToggleEnabled: (() -> Void)?
  var onOpenLastApplicationSettings: (() -> Void)?

  let mainMenu = NSMenu()

  private let appMenu = NSMenu()
  private let fileMenu = NSMenu()
  private let navigateMenu = NSMenu()
  private let helpMenu = NSMenu()
  private let settingsItem = NSMenuItem()
  private let toggleEnabledItem = NSMenuItem()
  private let quitItem = NSMenuItem()
  private let closeWindowItem = NSMenuItem()
  private let meetingItem = NSMenuItem()
  private let chatItem = NSMenuItem()
  private let mailItem = NSMenuItem()
  private let developmentItem = NSMenuItem()
  private let browserItem = NSMenuItem()
  private let finderItem = NSMenuItem()
  private let macOSItem = NSMenuItem()
  private let applicationsItem = NSMenuItem()
  private let diagnosticsItem = NSMenuItem()
  private let lastApplicationItem = NSMenuItem()
  private let shortcutGuideItem = NSMenuItem()
  private var language: AppLanguage = .english
  private var isEnabled = true

  override init() {
    super.init()
    configureMenus()
    applyLanguage()
  }

  func install() {
    NSApplication.shared.mainMenu = mainMenu
  }

  func setLanguage(_ language: AppLanguage) {
    self.language = language
    applyLanguage()
  }

  func setEnabled(_ enabled: Bool) {
    isEnabled = enabled
    applyLanguage()
  }

  private func configureMenus() {
    addTopLevelMenu(appMenu, title: "Rinvio")
    addTopLevelMenu(fileMenu, title: "File")
    addTopLevelMenu(navigateMenu, title: "Navigate")
    addTopLevelMenu(helpMenu, title: "Help")

    configure(settingsItem, action: #selector(openSettings), key: ",")
    configure(
      toggleEnabledItem,
      action: #selector(toggleEnabled),
      key: "p",
      modifiers: [.option, .shift]
    )
    configure(quitItem, action: #selector(quit), key: "q")
    appMenu.addItem(settingsItem)
    appMenu.addItem(toggleEnabledItem)
    appMenu.addItem(.separator())
    appMenu.addItem(quitItem)

    closeWindowItem.action = #selector(NSWindow.performClose(_:))
    closeWindowItem.keyEquivalent = "w"
    closeWindowItem.keyEquivalentModifierMask = [.command]
    fileMenu.addItem(closeWindowItem)

    configure(meetingItem, section: .meeting, key: "m")
    configure(chatItem, section: .chat, key: "c")
    configure(mailItem, section: .mail, key: "e")
    configure(developmentItem, section: .development, key: "d")
    configure(browserItem, section: .browser, key: "b")
    configure(finderItem, section: .finder, key: "f")
    configure(macOSItem, section: .system, key: "s")
    configure(applicationsItem, section: .applications, key: "a")
    configure(diagnosticsItem, section: .diagnostics, key: "i")
    configure(
      lastApplicationItem,
      action: #selector(openLastApplicationSettings),
      key: "a",
      modifiers: [.option, .shift]
    )
    navigateMenu.addItem(meetingItem)
    navigateMenu.addItem(chatItem)
    navigateMenu.addItem(mailItem)
    navigateMenu.addItem(developmentItem)
    navigateMenu.addItem(browserItem)
    navigateMenu.addItem(.separator())
    navigateMenu.addItem(finderItem)
    navigateMenu.addItem(macOSItem)
    navigateMenu.addItem(.separator())
    navigateMenu.addItem(applicationsItem)
    navigateMenu.addItem(diagnosticsItem)
    navigateMenu.addItem(.separator())
    navigateMenu.addItem(lastApplicationItem)

    configure(
      shortcutGuideItem,
      action: #selector(showShortcutGuide),
      key: "/",
      modifiers: [.option]
    )
    helpMenu.addItem(shortcutGuideItem)
  }

  private func addTopLevelMenu(_ menu: NSMenu, title: String) {
    let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
    item.submenu = menu
    mainMenu.addItem(item)
  }

  private func configure(
    _ item: NSMenuItem,
    action: Selector,
    key: String,
    modifiers: NSEvent.ModifierFlags = [.command]
  ) {
    item.target = self
    item.action = action
    item.keyEquivalent = key
    item.keyEquivalentModifierMask = modifiers
  }

  private func configure(_ item: NSMenuItem, section: QuickDrawSection, key: String) {
    configure(item, action: #selector(openSection(_:)), key: key, modifiers: [.option])
    item.representedObject = section.rawValue
  }

  private func applyLanguage() {
    let copy = QuickDrawCopy(language: language)
    mainMenu.items[1].title = copy.fileMenu
    mainMenu.items[2].title = copy.navigateMenu
    mainMenu.items[3].title = copy.helpMenu
    settingsItem.title = copy.settings
    toggleEnabledItem.title = isEnabled ? copy.pauseQuickDraw : copy.enableQuickDraw
    quitItem.title = copy.quitQuickDraw
    closeWindowItem.title = copy.closeWindow
    meetingItem.title = copy.sectionTitle(.meeting)
    chatItem.title = copy.sectionTitle(.chat)
    mailItem.title = copy.sectionTitle(.mail)
    developmentItem.title = copy.sectionTitle(.development)
    browserItem.title = copy.sectionTitle(.browser)
    finderItem.title = copy.sectionTitle(.finder)
    macOSItem.title = copy.sectionTitle(.system)
    applicationsItem.title = copy.applications
    diagnosticsItem.title = copy.diagnostics
    lastApplicationItem.title = copy.lastUsedApplicationSettings
    shortcutGuideItem.title = copy.shortcutGuide
  }

  @objc private func openSettings() {
    onSelectSection?(.settings)
  }

  @objc private func toggleEnabled() {
    onToggleEnabled?()
  }

  @objc private func quit() {
    NSApplication.shared.terminate(nil)
  }

  @objc private func openSection(_ sender: NSMenuItem) {
    guard
      let rawValue = sender.representedObject as? String,
      let section = QuickDrawSection(rawValue: rawValue)
    else { return }
    onSelectSection?(section)
  }

  @objc private func openLastApplicationSettings() {
    onOpenLastApplicationSettings?()
  }

  @objc private func showShortcutGuide() {
    onShowShortcutGuide?()
  }
}
