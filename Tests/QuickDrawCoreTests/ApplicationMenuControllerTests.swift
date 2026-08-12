import AppKit
import QuickDrawCore
import XCTest

@testable import QuickDrawPoC

@MainActor
final class ApplicationMenuControllerTests: XCTestCase {
  func testDefinesForegroundApplicationShortcuts() {
    let controller = ApplicationMenuController()
    let items = controller.mainMenu.items.flatMap { $0.submenu?.items ?? [] }
    let expected: [(String, NSEvent.ModifierFlags)] = [
      ("m", [.option]),
      ("c", [.option]),
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

  func testOptionNavigationShortcutsSelectTheirSections() throws {
    let controller = ApplicationMenuController()
    var sections: [QuickDrawSection] = []
    controller.onSelectSection = { sections.append($0) }

    let items = controller.mainMenu.items.flatMap { $0.submenu?.items ?? [] }
    for key in ["m", "c", "d", "b", "f", "s", "a", "i"] {
      let item = try XCTUnwrap(
        items.first {
          $0.keyEquivalent == key && $0.keyEquivalentModifierMask == [.option]
        })
      let action = try XCTUnwrap(item.action)
      XCTAssertTrue(NSApplication.shared.sendAction(action, to: item.target, from: item))
    }

    XCTAssertEqual(
      sections,
      [.meeting, .chat, .development, .browser, .finder, .system, .applications, .diagnostics]
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
}
