import XCTest
@testable import QuickDrawPoC

final class ConfiguredSystemShortcutDetectorTests: XCTestCase {
  func testUnknownKeyCodeStillHasDisplayValue() {
    XCTAssertEqual(ConfiguredSystemShortcutDetector.keyDisplay(for: 82), "Key 82")
  }

  func testSpaceHasReadableDisplayValue() {
    XCTAssertEqual(ConfiguredSystemShortcutDetector.keyDisplay(for: 49), "Space")
  }
}
