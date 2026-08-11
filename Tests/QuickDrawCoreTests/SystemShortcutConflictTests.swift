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

  func testNewDeveloperToolsDefaultStillUsesReservedShortcutDetection() throws {
    let expected: [Action: KnownSystemShortcut] = [
      .openDeveloperTools: .showInspector
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
