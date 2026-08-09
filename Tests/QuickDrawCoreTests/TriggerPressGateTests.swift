import QuickDrawCore
import XCTest

final class TriggerPressGateTests: XCTestCase {
  func testFirstPressInvokes() {
    var gate = TriggerPressGate()

    XCTAssertTrue(gate.shouldInvoke(for: .pressed))
  }

  func testRepeatedPressesAreIgnoredUntilRelease() {
    var gate = TriggerPressGate()

    XCTAssertTrue(gate.shouldInvoke(for: .pressed))
    XCTAssertFalse(gate.shouldInvoke(for: .pressed))
    XCTAssertFalse(gate.shouldInvoke(for: .pressed))
    XCTAssertFalse(gate.shouldInvoke(for: .released))
    XCTAssertTrue(gate.shouldInvoke(for: .pressed))
  }

  func testReleaseWithoutPressDoesNotInvoke() {
    var gate = TriggerPressGate()

    XCTAssertFalse(gate.shouldInvoke(for: .released))
  }
}
