import QuickDrawCore
import XCTest

final class ShortcutEventPlannerTests: XCTestCase {
  func testPlanCreatesOneKeyDownAndOneMatchingKeyUp() {
    let shortcut = KeyStroke(
      virtualKeyCode: 46,
      modifiers: [.command, .shift],
      displayValue: "⌘⇧M"
    )

    let events = ShortcutEventPlanner.plan(for: shortcut)

    XCTAssertEqual(events.count, 2)
    XCTAssertEqual(events.map(\.phase), [.keyDown, .keyUp])
    XCTAssertEqual(events.map(\.virtualKeyCode), [46, 46])
    XCTAssertEqual(events.map(\.modifiers), [[.command, .shift], [.command, .shift]])
    XCTAssertEqual(
      events.map(\.sourceMarker),
      [ShortcutEventPlanner.quickDrawSourceMarker, ShortcutEventPlanner.quickDrawSourceMarker]
    )
  }
}
