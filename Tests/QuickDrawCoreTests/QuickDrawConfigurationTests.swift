import Foundation
import QuickDrawCore
import XCTest

final class QuickDrawConfigurationTests: XCTestCase {
  func testDefaultsComeFromCatalogWithoutStoredOverrides() {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    XCTAssertEqual(store.trigger(for: .mute)?.displayValue, "⌥M")
    XCTAssertEqual(store.shortcut(for: .camera, target: .zoomWorkplace)?.displayValue, "⌘⇧V")
    XCTAssertEqual(store.trigger(for: .openChat)?.displayValue, "⌥O")
    XCTAssertNil(store.shortcut(for: .openChat, target: .microsoftTeams))
    XCTAssertTrue(store.configuration.triggerOverrides.isEmpty)
    XCTAssertTrue(store.configuration.unassignedTriggers.isEmpty)
    XCTAssertTrue(store.configuration.shortcutOverrides.isEmpty)
    XCTAssertTrue(store.configuration.disabledApplications.isEmpty)
    XCTAssertTrue(store.configuration.enabledOptInTargets.isEmpty)
    XCTAssertTrue(store.isApplicationEnabled(.zoomWorkplace))
    XCTAssertFalse(store.isApplicationEnabled(.macOS))
    XCTAssertFalse(store.isApplicationEnabled(.finder))
  }

  func testMailSuggestedTriggersPreserveCommonCommandActions() {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    XCTAssertEqual(store.trigger(for: .composeEmail)?.displayValue, "⌘N")
    XCTAssertEqual(store.trigger(for: .findInEmail)?.displayValue, "⌘F")
    XCTAssertEqual(store.trigger(for: .searchAllEmail)?.displayValue, "⇧⌘F")
    XCTAssertEqual(store.trigger(for: .replyEmail)?.displayValue, "⌥R")
    XCTAssertEqual(store.trigger(for: .replyAllEmail)?.displayValue, "⇧⌥R")
    XCTAssertEqual(store.trigger(for: .forwardEmail)?.displayValue, "⌥F")
    XCTAssertEqual(store.trigger(for: .archiveEmail)?.displayValue, "⌥A")
    XCTAssertEqual(store.trigger(for: .checkNewMail)?.displayValue, "⌥G")
  }

  func testTriggerOverrideCanBeRestoredBySettingDefault() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let custom = KeyStroke(virtualKeyCode: 103, modifiers: [], displayValue: "F11")

    try store.setTriggerOverride(custom, for: .mute)
    XCTAssertEqual(store.trigger(for: .mute), custom)
    XCTAssertTrue(store.isTriggerOverridden(for: .mute))

    let defaultTrigger = try XCTUnwrap(ActionCatalog.defaultTrigger(for: .mute))
    try store.setTriggerOverride(defaultTrigger, for: .mute)
    XCTAssertEqual(store.trigger(for: .mute)?.displayValue, "⌥M")
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
    XCTAssertEqual(store.trigger(for: .openChat)?.displayValue, "⌥O")
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
    XCTAssertEqual(store.trigger(for: .openChat)?.displayValue, "⌥O")
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

  func testTriggerOverridesCanSwapShortcutsAtomically() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let muteTrigger = try XCTUnwrap(ActionCatalog.defaultTrigger(for: .mute))
    let cameraTrigger = try XCTUnwrap(ActionCatalog.defaultTrigger(for: .camera))

    try store.setTriggerOverrides([
      .mute: cameraTrigger,
      .camera: muteTrigger,
    ])

    XCTAssertEqual(store.trigger(for: .mute), cameraTrigger)
    XCTAssertEqual(store.trigger(for: .camera), muteTrigger)
  }

  func testBatchTriggerOverrideRejectsDuplicateFinalConfiguration() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let cameraTrigger = try XCTUnwrap(ActionCatalog.defaultTrigger(for: .camera))

    XCTAssertThrowsError(
      try store.setTriggerOverrides([.mute: cameraTrigger])
    ) { error in
      XCTAssertEqual(error as? QuickDrawConfigurationError, .duplicateTrigger(.camera))
    }
    XCTAssertEqual(store.trigger(for: .mute), ActionCatalog.defaultTrigger(for: .mute))
  }

  func testBatchTriggerOverrideClearsUnassignedStateAndPersists() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directory.appendingPathComponent("configuration.json")
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = QuickDrawConfigurationStore(fileURL: fileURL)
    let custom = KeyStroke(virtualKeyCode: 103, modifiers: [], displayValue: "F11")

    try store.unassignTrigger(for: .openChat)
    try store.setTriggerOverrides([.openChat: custom])

    let reloaded = QuickDrawConfigurationStore(fileURL: fileURL)
    XCTAssertEqual(reloaded.trigger(for: .openChat), custom)
    XCTAssertFalse(reloaded.configuration.unassignedTriggers.contains(.openChat))
  }

  func testActionResetRestoresUnassignedTrigger() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    try store.unassignTrigger(for: .openChat)
    try store.resetAction(.openChat)

    XCTAssertEqual(store.trigger(for: .openChat)?.displayValue, "⌥O")
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

    XCTAssertTrue(store.actions(withTriggerModifiers: [.command, .shift]).contains(.mute))
    XCTAssertFalse(store.actions(withTriggerModifiers: [.command, .option]).contains(.mute))
    XCTAssertTrue(store.actions(withTriggerModifiers: [.option]).contains(.camera))
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

  func testEveryBuiltInActionHasASafeTriggerUniqueWithinItsRoutingScope() throws {
    let triggers = try Action.allCases.map {
      try XCTUnwrap(ActionCatalog.defaultTrigger(for: $0))
    }

    for (index, action) in Action.allCases.enumerated() {
      let trigger = try XCTUnwrap(ActionCatalog.defaultTrigger(for: action))
      for candidate in Action.allCases.dropFirst(index + 1)
      where ActionCatalog.triggerScopesOverlap(action, candidate) {
        XCTAssertFalse(
          ActionCatalog.defaultTrigger(for: candidate)?.matchesPhysicalShortcut(trigger) == true,
          "\(action.rawValue) conflicts with \(candidate.rawValue)"
        )
      }
    }
    XCTAssertEqual(ActionCatalog.defaultTrigger(for: .focusNextRegion)?.displayValue, "F6")
    XCTAssertEqual(ActionCatalog.defaultTrigger(for: .focusPreviousRegion)?.displayValue, "⇧F6")
    XCTAssertTrue(
      zip(Action.allCases, triggers).filter { action, trigger in
        action.domain != .system
          && trigger.displayValue != "F6" && trigger.displayValue != "⇧F6"
      }.allSatisfy { _, trigger in
        !trigger.modifiers.isDisjoint(with: [.command, .control, .option])
      }
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
    XCTAssertFalse(store.isApplicationEnabled(.macOS))
    XCTAssertFalse(store.isApplicationEnabled(.finder))
  }

  func testNewSuggestedTriggersMatchDesignPrinciples() {
    let expected: [Action: String] = [
      .mute: "⌥M", .camera: "⌥C", .raiseHand: "⌥H", .openChat: "⌥O",
      .showParticipants: "⌥P", .toggleCaptions: "⌥L", .shareScreen: "⌥S",
      .switchCamera: "⌥X", .pictureInPicture: "⌥I", .leaveMeeting: "⌥G",
      .reactionLike: "⌥1", .reactionHeart: "⌥2", .reactionClap: "⌥3",
      .reactionLaugh: "⌥4", .reactionWow: "⌥5", .reactionCelebrate: "⌥6",
      .newSession: "⌥N", .toggleTerminal: "⌥T", .commandPalette: "⌥K",
      .quickOpen: "⌥O", .focusSidebar: "⌥F1", .focusMainColumn: "⌥F2",
      .focusTerminal: "⌥F3", .hardReload: "⇧⌘R", .nextTab: "⌥]",
      .previousTab: "⇧⌥]", .openDownloads: "⌥D", .openDeveloperTools: "⌘⌥I",
      .reopenClosedTab: "⇧⌘T",
      .missionControl: "⇧⌘↑", .applicationExpose: "⇧⌘↓",
      .previousDesktop: "⇧⌘←", .nextDesktop: "⇧⌘→",
      .showDesktop: "F11", .showNotificationCenter: "⌃⌘N",
      .toggleDoNotDisturb: "⌃⌘D", .toggleStageManager: "⌃⌘S",
      .fillWindow: "⌃⌘↑", .tileWindowLeft: "⌃⌘←", .tileWindowRight: "⌃⌘→",
      .switchDesktop1: "⌘1", .switchDesktop2: "⌘2", .switchDesktop3: "⌘3",
      .switchDesktop4: "⌘4", .switchDesktop5: "⌘5",
    ]

    for (action, displayValue) in expected {
      XCTAssertEqual(ActionCatalog.defaultTrigger(for: action)?.displayValue, displayValue)
    }
    XCTAssertEqual(ActionCatalog.defaultTrigger(for: .goToSymbol)?.displayValue, "⌃⌥O")
    XCTAssertEqual(ActionCatalog.defaultTrigger(for: .runProject)?.displayValue, "⌃⌥G")
    XCTAssertEqual(ActionCatalog.defaultTrigger(for: .nextIssue)?.displayValue, "⌃⌥]")
  }

  func testSchemaOneMigrationPreservesCustomClearAndLegacySuggestedTriggers() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directory.appendingPathComponent("configuration.json")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let legacyData = try XCTUnwrap(
      """
      {
        "schemaVersion": 1,
        "triggerOverrides": [{
          "action": "mute",
          "shortcut": {"virtualKeyCode":103,"modifiers":[],"displayValue":"F11"}
        }],
        "unassignedTriggers": ["openChat"],
        "shortcutOverrides": [],
        "disabledApplications": ["zoomWorkplace"]
      }
      """.data(using: .utf8)
    )
    try legacyData.write(to: fileURL)

    let migrated = QuickDrawConfigurationStore(fileURL: fileURL)

    XCTAssertEqual(migrated.configuration.schemaVersion, 2)
    XCTAssertEqual(migrated.trigger(for: .mute)?.displayValue, "F11")
    XCTAssertNil(migrated.trigger(for: .openChat))
    XCTAssertEqual(migrated.trigger(for: .camera)?.displayValue, "⌘⌥C")
    XCTAssertFalse(migrated.isApplicationEnabled(.zoomWorkplace))
    XCTAssertFalse(migrated.isApplicationEnabled(.macOS))
    XCTAssertFalse(migrated.isApplicationEnabled(.finder))

    let persistedMigration = QuickDrawConfigurationStore(fileURL: fileURL)
    XCTAssertEqual(persistedMigration.configuration, migrated.configuration)

    try migrated.setApplicationEnabled(false, for: .visualStudioCode)
    let reloaded = QuickDrawConfigurationStore(fileURL: fileURL)
    XCTAssertEqual(reloaded.configuration, migrated.configuration)

    try reloaded.resetTrigger(for: .camera)
    XCTAssertEqual(reloaded.trigger(for: .camera)?.displayValue, "⌥C")
  }

  func testMacOSIsAlwaysManagedOutsideQuickDraw() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    try store.setApplicationEnabled(true, for: .macOS)
    XCTAssertFalse(store.isApplicationEnabled(.macOS))
    try store.setApplicationEnabled(true, for: .macOS)
    XCTAssertFalse(store.isApplicationEnabled(.macOS))
    XCTAssertFalse(store.configuration.enabledOptInTargets.contains(.macOS))
  }

  func testFinderCanBeOptedInWithoutSystemWideConfirmation() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)

    try store.setApplicationEnabled(true, for: .finder)
    XCTAssertTrue(store.isApplicationEnabled(.finder))
    XCTAssertEqual(store.configuration.enabledOptInTargets, [.finder])
  }

  func testSystemSettingsRecommendationsDoNotBlockApplicationTriggers() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let systemRecommendation = try XCTUnwrap(store.trigger(for: .showDesktop))

    XCTAssertNoThrow(try store.setTriggerOverride(systemRecommendation, for: .mute))
    XCTAssertEqual(store.trigger(for: .mute), systemRecommendation)
  }
}
