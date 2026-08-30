import AppKit
import QuickDrawCore
import XCTest

@testable import QuickDrawShortcuts

@MainActor
final class ApplicationMenuControllerTests: XCTestCase {
  func testSupportURLPointsToPublicHelpPage() {
    XCTAssertEqual(
      QuickDrawAppModel.supportURL.absoluteString,
      "https://keishingu.github.io/Rinvio/support.html"
    )
  }

  func testPrivacyURLPointsToPublicPolicyPage() {
    XCTAssertEqual(
      QuickDrawAppModel.privacyPolicyURL.absoluteString,
      "https://keishingu.github.io/Rinvio/privacy.html"
    )
  }

  func testDefinesForegroundApplicationShortcuts() {
    let controller = ApplicationMenuController()
    let items = controller.mainMenu.items.flatMap { $0.submenu?.items ?? [] }
    let expected: [(String, NSEvent.ModifierFlags)] = [
      ("m", [.option]),
      ("c", [.option]),
      ("e", [.option]),
      ("d", [.option]),
      ("b", [.option]),
      ("f", [.option]),
      ("s", [.option]),
      ("a", [.option]),
      ("i", [.option]),
      (",", [.command]),
      ("/", [.option]),
      ("p", [.option, .shift]),
      ("a", [.option, .shift]),
      ("w", [.command]),
      ("q", [.command]),
    ]

    for (key, modifiers) in expected {
      let item = items.first {
        $0.keyEquivalent == key && $0.keyEquivalentModifierMask == modifiers
      }
      XCTAssertNotNil(item, "Missing menu shortcut for \(modifiers) + \(key)")
      XCTAssertEqual(item?.keyEquivalentModifierMask, modifiers)
    }
  }

  func testModelNavigationUsesExistingSections() {
    let model = QuickDrawAppModel(
      defaults: UserDefaults(suiteName: #function)!,
      configurationStore: QuickDrawConfigurationStore(fileURL: nil)
    )

    model.selectSection(.diagnostics)
    XCTAssertEqual(model.selectedSection, .diagnostics)

    model.openApplicationSettings(for: .finder)
    XCTAssertEqual(model.selectedSection, .applications)
    XCTAssertEqual(model.selectedApplicationID, "system:finder")
  }

  func testShortcutAlignmentAcceptsActionsFromAnyCategory() throws {
    let model = QuickDrawAppModel(
      defaults: UserDefaults(suiteName: #function)!,
      configurationStore: QuickDrawConfigurationStore(fileURL: nil)
    )
    let application = try XCTUnwrap(model.applications.first { $0.target == .appleNotes })
    var receivedTarget: ActionTarget?
    var receivedActions: [Action] = []
    model.onAlignTriggers = { target, actions in
      receivedTarget = target
      receivedActions = actions
      return TriggerAlignmentResult(
        appliedCount: actions.count,
        skippedDuplicateCount: 0,
        error: nil
      )
    }

    model.alignTriggers(to: application, actions: [.newNote, .findInNote])

    XCTAssertEqual(receivedTarget, .appleNotes)
    XCTAssertEqual(receivedActions, [.newNote, .findInNote])
    XCTAssertEqual(model.triggerAlignmentNotice?.appliedCount, 2)
  }

  func testDeveloperModeDefaultsOffAndPersists() {
    let suiteName = "\(#function).\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let model = QuickDrawAppModel(
      defaults: defaults,
      configurationStore: QuickDrawConfigurationStore(fileURL: nil)
    )
    XCTAssertFalse(model.isDeveloperModeEnabled)

    model.setDeveloperModeEnabled(true)
    let reloadedModel = QuickDrawAppModel(
      defaults: defaults,
      configurationStore: QuickDrawConfigurationStore(fileURL: nil)
    )
    XCTAssertTrue(reloadedModel.isDeveloperModeEnabled)
  }

  func testDisablingDeveloperModeAlsoDisablesDryRun() {
    let model = QuickDrawAppModel(
      defaults: UserDefaults(suiteName: #function)!,
      configurationStore: QuickDrawConfigurationStore(fileURL: nil)
    )
    var dryRunUpdates: [Bool] = []
    model.onSetDryRun = { dryRunUpdates.append($0) }

    model.setDeveloperModeEnabled(true)
    model.setDryRunEnabled(true)
    model.setDeveloperModeEnabled(false)

    XCTAssertFalse(model.isDryRunEnabled)
    XCTAssertEqual(dryRunUpdates, [true, false])
  }

  func testPermissionRequestsOpenTheMatchingSystemSettingsPaneWhenStillRequired() {
    var openedURLs: [URL] = []
    let model = QuickDrawAppModel(
      defaults: UserDefaults(suiteName: #function)!,
      configurationStore: QuickDrawConfigurationStore(fileURL: nil),
      openURL: {
        openedURLs.append($0)
        return true
      }
    )
    model.onRefreshPermissions = {
      KeyboardPermissionState(
        hasInputMonitoringAccess: false,
        hasPostEventAccess: false
      )
    }

    model.requestInputMonitoring()
    model.requestPostEvent()

    XCTAssertEqual(
      openedURLs.map(\.absoluteString),
      [
        "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent",
        "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
      ]
    )
  }

  func testPermissionRequestsDoNotOpenSystemSettingsWhenAlreadyGranted() {
    var openedURLs: [URL] = []
    let model = QuickDrawAppModel(
      defaults: UserDefaults(suiteName: #function)!,
      configurationStore: QuickDrawConfigurationStore(fileURL: nil),
      openURL: {
        openedURLs.append($0)
        return true
      }
    )
    model.onRefreshPermissions = {
      KeyboardPermissionState(
        hasInputMonitoringAccess: true,
        hasPostEventAccess: true
      )
    }

    model.requestInputMonitoring()
    model.requestPostEvent()

    XCTAssertTrue(openedURLs.isEmpty)
  }

  func testOptionNavigationShortcutsSelectTheirSections() throws {
    let controller = ApplicationMenuController()
    var sections: [QuickDrawSection] = []
    controller.onSelectSection = { sections.append($0) }

    let items = controller.mainMenu.items.flatMap { $0.submenu?.items ?? [] }
    for key in ["m", "n", "c", "e", "d", "b", "f", "s", "a", "i"] {
      let item = try XCTUnwrap(
        items.first {
          $0.keyEquivalent == key && $0.keyEquivalentModifierMask == [.option]
        })
      let action = try XCTUnwrap(item.action)
      XCTAssertTrue(NSApplication.shared.sendAction(action, to: item.target, from: item))
    }

    XCTAssertEqual(
      sections,
      [
        .meeting, .note, .chat, .mail, .development, .browser, .finder, .system,
        .applications, .diagnostics,
      ]
    )
  }

  func testApplicationSpecificOptionShortcutsInvokeTheirActions() throws {
    let controller = ApplicationMenuController()
    var didToggleEnabled = false
    var didOpenLastApplicationSettings = false
    var didShowShortcutGuide = false
    controller.onToggleEnabled = { didToggleEnabled = true }
    controller.onOpenLastApplicationSettings = { didOpenLastApplicationSettings = true }
    controller.onShowShortcutGuide = { didShowShortcutGuide = true }

    let items = controller.mainMenu.items.flatMap { $0.submenu?.items ?? [] }
    let shortcuts: [(String, NSEvent.ModifierFlags)] = [
      ("p", [.option, .shift]),
      ("a", [.option, .shift]),
      ("/", [.option]),
    ]
    for (key, modifiers) in shortcuts {
      let item = try XCTUnwrap(
        items.first {
          $0.keyEquivalent == key && $0.keyEquivalentModifierMask == modifiers
        })
      let action = try XCTUnwrap(item.action)
      XCTAssertTrue(NSApplication.shared.sendAction(action, to: item.target, from: item))
    }

    XCTAssertTrue(didToggleEnabled)
    XCTAssertTrue(didOpenLastApplicationSettings)
    XCTAssertTrue(didShowShortcutGuide)
  }

  func testRinvioDefaultsMigrationPreservesNewValuesAndRunsOnlyOnce() {
    let suiteName = "\(#function).\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(AppLanguage.japanese.rawValue, forKey: AppLanguage.defaultsKey)

    RinvioDefaultsMigration.migrateIfNeeded(
      defaults: defaults,
      legacyDomain: [
        AppLanguage.defaultsKey: AppLanguage.english.rawValue,
        "cheatSheetEnabled": false,
        "developerModeEnabled": true,
      ]
    )

    XCTAssertEqual(defaults.string(forKey: AppLanguage.defaultsKey), AppLanguage.japanese.rawValue)
    XCTAssertFalse(defaults.bool(forKey: "cheatSheetEnabled"))
    XCTAssertTrue(defaults.bool(forKey: "developerModeEnabled"))

    RinvioDefaultsMigration.migrateIfNeeded(
      defaults: defaults,
      legacyDomain: [
        "cheatSheetEnabled": true,
        "developerModeEnabled": false,
      ]
    )
    XCTAssertFalse(defaults.bool(forKey: "cheatSheetEnabled"))
    XCTAssertTrue(defaults.bool(forKey: "developerModeEnabled"))
  }
}
