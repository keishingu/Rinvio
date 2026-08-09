import QuickDrawCore
import XCTest

final class SystemShortcutConflictTests: XCTestCase {
  func testDetectsKnownCommandOptionConflict() {
    let shortcut = KeyStroke(
      virtualKeyCode: 46,
      modifiers: [.command, .option],
      displayValue: "⌘⌥M"
    )

    XCTAssertEqual(
      SystemShortcutCatalog.knownConflict(for: shortcut),
      .minimizeAllWindows
    )
  }

  func testDoesNotFlagSameKeyWithDifferentModifiers() {
    let shortcut = KeyStroke(
      virtualKeyCode: 46,
      modifiers: [.command, .shift],
      displayValue: "⌘⇧M"
    )

    XCTAssertNil(SystemShortcutCatalog.knownConflict(for: shortcut))
  }

  func testEveryExpectedDefaultConflictIsCatalogued() throws {
    let expected: [Action: KnownSystemShortcut] = [
      .mute: .minimizeAllWindows,
      .camera: .copyStyle,
      .raiseHand: .hideOtherApplications,
      .toggleCaptions: .openDownloads,
      .pictureInPicture: .showInspector,
    ]

    for (action, conflict) in expected {
      XCTAssertEqual(
        SystemShortcutCatalog.knownConflict(
          for: try XCTUnwrap(ActionCatalog.defaultTrigger(for: action))
        ),
        conflict
      )
    }
  }
}
