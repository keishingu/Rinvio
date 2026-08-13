import QuickDrawCore
import XCTest

@testable import QuickDrawShortcuts

final class ConfiguredSystemShortcutDetectorTests: XCTestCase {
  func testUnknownKeyCodeStillHasDisplayValue() {
    XCTAssertEqual(ConfiguredSystemShortcutDetector.keyDisplay(for: 82), "Key 82")
  }

  func testSpaceHasReadableDisplayValue() {
    XCTAssertEqual(ConfiguredSystemShortcutDetector.keyDisplay(for: 49), "Space")
  }

  func testFunctionModifierIsIgnoredForConflictIdentity() {
    XCTAssertEqual(
      ConfiguredSystemShortcutDetector.normalizedConflictModifiers([.control, .function]),
      [.control]
    )
  }
}
