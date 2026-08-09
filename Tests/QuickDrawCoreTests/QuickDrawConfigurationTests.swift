import Foundation
import QuickDrawCore
import XCTest

final class QuickDrawConfigurationTests: XCTestCase {
  func testDefaultsComeFromCatalogWithoutStoredOverrides() {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    XCTAssertEqual(store.trigger(for: .mute)?.displayValue, "F6")
    XCTAssertEqual(store.shortcut(for: .camera, target: .zoomWorkplace)?.displayValue, "⌘⇧V")
    XCTAssertNil(store.trigger(for: .openChat))
    XCTAssertNil(store.shortcut(for: .openChat, target: .microsoftTeams))
    XCTAssertTrue(store.configuration.triggerOverrides.isEmpty)
    XCTAssertTrue(store.configuration.shortcutOverrides.isEmpty)
  }

  func testTriggerOverrideCanBeRestoredBySettingDefault() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let custom = KeyStroke(virtualKeyCode: 103, modifiers: [], displayValue: "F11")

    try store.setTriggerOverride(custom, for: .mute)
    XCTAssertEqual(store.trigger(for: .mute), custom)
    XCTAssertTrue(store.isTriggerOverridden(for: .mute))

    let defaultTrigger = try XCTUnwrap(ActionCatalog.defaultTrigger(for: .mute))
    try store.setTriggerOverride(defaultTrigger, for: .mute)
    XCTAssertEqual(store.trigger(for: .mute)?.displayValue, "F6")
    XCTAssertFalse(store.isTriggerOverridden(for: .mute))
  }

  func testRejectsUnsafeBareLetterTrigger() {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let bareLetter = KeyStroke(virtualKeyCode: 0, modifiers: [], displayValue: "A")

    XCTAssertThrowsError(try store.setTriggerOverride(bareLetter, for: .mute)) { error in
      XCTAssertEqual(error as? QuickDrawConfigurationError, .unsafeTrigger)
    }
  }

  func testRejectsDuplicateTrigger() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let cameraTrigger = try XCTUnwrap(ActionCatalog.defaultTrigger(for: .camera))

    XCTAssertThrowsError(
      try store.setTriggerOverride(cameraTrigger, for: .mute)
    ) { error in
      XCTAssertEqual(error as? QuickDrawConfigurationError, .duplicateTrigger(.camera))
    }
  }

  func testUnassignedActionCanReceiveAndResetTrigger() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let custom = KeyStroke(
      virtualKeyCode: 8,
      modifiers: [.command, .option],
      displayValue: "⌥⌘C"
    )

    try store.setTriggerOverride(custom, for: .openChat)
    XCTAssertEqual(store.trigger(for: .openChat), custom)
    XCTAssertTrue(store.isTriggerOverridden(for: .openChat))

    try store.resetTrigger(for: .openChat)
    XCTAssertNil(store.trigger(for: .openChat))
    XCTAssertFalse(store.isTriggerOverridden(for: .openChat))
  }

  func testMappingOverrideAndActionResetRemoveOnlySelectedAction() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let muteOverride = KeyStroke(
      virtualKeyCode: 11,
      modifiers: [.command, .option],
      displayValue: "⌥⌘B"
    )
    let cameraOverride = KeyStroke(
      virtualKeyCode: 8,
      modifiers: [.command, .option],
      displayValue: "⌥⌘C"
    )
    try store.setShortcutOverride(muteOverride, for: .mute, target: .zoomWorkplace)
    try store.setShortcutOverride(cameraOverride, for: .camera, target: .zoomWorkplace)
    try store.setTriggerOverride(
      KeyStroke(virtualKeyCode: 103, modifiers: [], displayValue: "F11"),
      for: .mute
    )

    try store.resetAction(.mute)

    XCTAssertFalse(store.isTriggerOverridden(for: .mute))
    XCTAssertFalse(store.isShortcutOverridden(for: .mute, target: .zoomWorkplace))
    XCTAssertEqual(store.shortcut(for: .camera, target: .zoomWorkplace), cameraOverride)
  }

  func testConfigurationPersistsAndReloads() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directory.appendingPathComponent("configuration.json")
    defer { try? FileManager.default.removeItem(at: directory) }

    let stored = QuickDrawConfigurationStore(fileURL: fileURL)
    let trigger = KeyStroke(virtualKeyCode: 103, modifiers: [], displayValue: "F11")
    let mapping = KeyStroke(
      virtualKeyCode: 11,
      modifiers: [.command, .option],
      displayValue: "⌥⌘B"
    )
    try stored.setTriggerOverride(trigger, for: .mute)
    try stored.setShortcutOverride(mapping, for: .camera, target: .microsoftTeams)

    let reloaded = QuickDrawConfigurationStore(fileURL: fileURL)

    XCTAssertEqual(reloaded.trigger(for: .mute), trigger)
    XCTAssertEqual(reloaded.shortcut(for: .camera, target: .microsoftTeams), mapping)
  }
}
