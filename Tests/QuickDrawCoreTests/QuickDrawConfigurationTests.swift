import Foundation
import QuickDrawCore
import XCTest

final class QuickDrawConfigurationTests: XCTestCase {
  func testDefaultsComeFromCatalogWithoutStoredOverrides() {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    XCTAssertEqual(store.trigger(for: .mute)?.displayValue, "⌘⌥M")
    XCTAssertEqual(store.shortcut(for: .camera, target: .zoomWorkplace)?.displayValue, "⌘⇧V")
    XCTAssertEqual(store.trigger(for: .openChat)?.displayValue, "⌘⌥O")
    XCTAssertNil(store.shortcut(for: .openChat, target: .microsoftTeams))
    XCTAssertTrue(store.configuration.triggerOverrides.isEmpty)
    XCTAssertTrue(store.configuration.unassignedTriggers.isEmpty)
    XCTAssertTrue(store.configuration.shortcutOverrides.isEmpty)
    XCTAssertTrue(store.configuration.disabledApplications.isEmpty)
    XCTAssertTrue(store.isApplicationEnabled(.zoomWorkplace))
  }

  func testTriggerOverrideCanBeRestoredBySettingDefault() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let custom = KeyStroke(virtualKeyCode: 103, modifiers: [], displayValue: "F11")

    try store.setTriggerOverride(custom, for: .mute)
    XCTAssertEqual(store.trigger(for: .mute), custom)
    XCTAssertTrue(store.isTriggerOverridden(for: .mute))

    let defaultTrigger = try XCTUnwrap(ActionCatalog.defaultTrigger(for: .mute))
    try store.setTriggerOverride(defaultTrigger, for: .mute)
    XCTAssertEqual(store.trigger(for: .mute)?.displayValue, "⌘⌥M")
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

  func testAllowsSameTriggerAcrossDisjointApplicationDomains() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let meetingTrigger = try XCTUnwrap(ActionCatalog.defaultTrigger(for: .mute))

    try store.setTriggerOverride(meetingTrigger, for: .hardReload)

    XCTAssertEqual(store.trigger(for: .hardReload), meetingTrigger)
  }

  func testRejectsSameTriggerAcrossDomainsSharedByTeams() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let meetingTrigger = try XCTUnwrap(ActionCatalog.defaultTrigger(for: .mute))

    XCTAssertThrowsError(
      try store.setTriggerOverride(meetingTrigger, for: .quickSwitcher)
    ) { error in
      XCTAssertEqual(error as? QuickDrawConfigurationError, .duplicateTrigger(.mute))
    }
  }

  func testActionCanReceiveAndResetTriggerOverride() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let custom = KeyStroke(virtualKeyCode: 103, modifiers: [], displayValue: "F11")

    try store.setTriggerOverride(custom, for: .openChat)
    XCTAssertEqual(store.trigger(for: .openChat), custom)
    XCTAssertTrue(store.isTriggerOverridden(for: .openChat))

    try store.resetTrigger(for: .openChat)
    XCTAssertEqual(store.trigger(for: .openChat)?.displayValue, "⌘⌥O")
    XCTAssertFalse(store.isTriggerOverridden(for: .openChat))
  }

  func testTriggerCanBeUnassignedAndRestoredToDefault() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    try store.unassignTrigger(for: .openChat)
    XCTAssertNil(store.trigger(for: .openChat))
    XCTAssertTrue(store.isTriggerOverridden(for: .openChat))
    XCTAssertEqual(store.configuration.unassignedTriggers, [.openChat])
    XCTAssertFalse(store.actions(withTriggerModifiers: [.command, .option]).contains(.openChat))

    try store.resetTrigger(for: .openChat)
    XCTAssertEqual(store.trigger(for: .openChat)?.displayValue, "⌘⌥O")
    XCTAssertFalse(store.isTriggerOverridden(for: .openChat))
    XCTAssertTrue(store.configuration.unassignedTriggers.isEmpty)
  }

  func testAssigningTriggerClearsUnassignedState() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let custom = KeyStroke(virtualKeyCode: 103, modifiers: [], displayValue: "F11")

    try store.unassignTrigger(for: .openChat)
    try store.setTriggerOverride(custom, for: .openChat)

    XCTAssertEqual(store.trigger(for: .openChat), custom)
    XCTAssertTrue(store.configuration.unassignedTriggers.isEmpty)
  }

  func testActionResetRestoresUnassignedTrigger() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    try store.unassignTrigger(for: .openChat)
    try store.resetAction(.openChat)

    XCTAssertEqual(store.trigger(for: .openChat)?.displayValue, "⌘⌥O")
    XCTAssertFalse(store.isTriggerOverridden(for: .openChat))
  }

  func testFindsActionsByTheirCurrentTriggerModifiers() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let commandShift = KeyStroke(
      virtualKeyCode: 46,
      modifiers: [.command, .shift],
      displayValue: "⌘⇧M"
    )
    try store.setTriggerOverride(commandShift, for: .mute)

    XCTAssertEqual(store.actions(withTriggerModifiers: [.command, .shift]), [.mute])
    XCTAssertFalse(store.actions(withTriggerModifiers: [.command, .option]).contains(.mute))
    XCTAssertTrue(store.actions(withTriggerModifiers: [.command, .option]).contains(.camera))
  }

  func testFindsApplicationShortcutsByModifiersWhenTriggerIsUnassigned() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    try store.unassignTrigger(for: .shareScreen)

    XCTAssertFalse(store.actions(withTriggerModifiers: [.command, .shift]).contains(.shareScreen))
    XCTAssertTrue(
      store.actions(
        withApplicationShortcutModifiers: [.command, .shift],
        for: .microsoftTeams
      ).contains(.shareScreen)
    )
  }

  func testApplicationShortcutModifierLookupUsesOverride() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let override = KeyStroke(
      virtualKeyCode: 1,
      modifiers: [.command, .option],
      displayValue: "⌘⌥S"
    )

    try store.setShortcutOverride(override, for: .shareScreen, target: .microsoftTeams)

    XCTAssertFalse(
      store.actions(
        withApplicationShortcutModifiers: [.command, .shift],
        for: .microsoftTeams
      ).contains(.shareScreen)
    )
    XCTAssertTrue(
      store.actions(
        withApplicationShortcutModifiers: [.command, .option],
        for: .microsoftTeams
      ).contains(.shareScreen)
    )
  }

  func testEveryBuiltInActionHasAUniqueSafeTrigger() throws {
    let triggers = try Action.allCases.map {
      try XCTUnwrap(ActionCatalog.defaultTrigger(for: $0))
    }

    XCTAssertEqual(
      Set(triggers.map { "\($0.virtualKeyCode)-\($0.modifiers)" }).count,
      Action.allCases.count
    )
    XCTAssertEqual(ActionCatalog.defaultTrigger(for: .focusNextRegion)?.displayValue, "F6")
    XCTAssertEqual(ActionCatalog.defaultTrigger(for: .focusPreviousRegion)?.displayValue, "⇧F6")
    XCTAssertTrue(
      triggers.filter {
        $0.displayValue != "F6" && $0.displayValue != "⇧F6"
      }.allSatisfy { $0.modifiers == [.command, .option] }
    )
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
    try stored.unassignTrigger(for: .openChat)
    try stored.setShortcutOverride(mapping, for: .camera, target: .microsoftTeams)
    try stored.setApplicationEnabled(false, for: .zoomWorkplace)

    let reloaded = QuickDrawConfigurationStore(fileURL: fileURL)

    XCTAssertEqual(reloaded.trigger(for: .mute), trigger)
    XCTAssertNil(reloaded.trigger(for: .openChat))
    XCTAssertEqual(reloaded.configuration.unassignedTriggers, [.openChat])
    XCTAssertEqual(reloaded.shortcut(for: .camera, target: .microsoftTeams), mapping)
    XCTAssertFalse(reloaded.isApplicationEnabled(.zoomWorkplace))
    XCTAssertTrue(reloaded.isApplicationEnabled(.microsoftTeams))
  }

  func testApplicationCanBeExcludedAndIncludedAgain() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    try store.setApplicationEnabled(false, for: .visualStudioCode)
    XCTAssertFalse(store.isApplicationEnabled(.visualStudioCode))
    XCTAssertEqual(store.configuration.disabledApplications, [.visualStudioCode])

    try store.setApplicationEnabled(true, for: .visualStudioCode)
    XCTAssertTrue(store.isApplicationEnabled(.visualStudioCode))
    XCTAssertTrue(store.configuration.disabledApplications.isEmpty)
  }

  func testConfigurationWithoutApplicationEnablementFieldStillLoads() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directory.appendingPathComponent("configuration.json")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let legacyData = try XCTUnwrap(
      """
      {
        "schemaVersion": 1,
        "triggerOverrides": [],
        "shortcutOverrides": []
      }
      """.data(using: .utf8)
    )
    try legacyData.write(to: fileURL)

    let store = QuickDrawConfigurationStore(fileURL: fileURL)

    XCTAssertTrue(store.configuration.disabledApplications.isEmpty)
    XCTAssertTrue(store.configuration.unassignedTriggers.isEmpty)
    XCTAssertTrue(store.isApplicationEnabled(.ghostty))
  }
}
