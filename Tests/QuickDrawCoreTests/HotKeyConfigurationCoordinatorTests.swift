import QuickDrawCore
import XCTest

@testable import QuickDrawShortcuts

final class HotKeyConfigurationCoordinatorTests: XCTestCase {
  func testAlignsTriggersForANonDevelopmentCategory() {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let coordinator = HotKeyConfigurationCoordinator(
      registrar: GlobalHotKeyRegistrar(),
      store: store
    )
    coordinator.setRegistrationAllowed(false)
    let meetingTrigger = store.trigger(for: .mute)

    let result = coordinator.alignTriggers(
      [.newNote, .openNote, .findInNote, .previousNote, .nextNote],
      to: .appleNotes
    )

    XCTAssertNil(result.error)
    XCTAssertEqual(result.appliedCount, 5)
    XCTAssertEqual(store.trigger(for: .newNote)?.displayValue, "⌘N")
    XCTAssertEqual(store.trigger(for: .openNote)?.displayValue, "⌥⌘F")
    XCTAssertEqual(store.trigger(for: .nextNote)?.displayValue, "⌥⌘]")
    XCTAssertEqual(store.trigger(for: .mute), meetingTrigger)
  }
}
