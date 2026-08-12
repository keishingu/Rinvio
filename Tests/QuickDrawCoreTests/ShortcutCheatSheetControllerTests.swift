import QuickDrawCore
import XCTest

@testable import QuickDrawPoC

@MainActor
final class ShortcutCheatSheetControllerTests: XCTestCase {
  func testNonModifierKeySuppressesHUDUntilModifiersAreReleased() {
    let controller = ShortcutCheatSheetController(
      configurationStore: QuickDrawConfigurationStore(fileURL: nil),
      foregroundProvider: ForegroundApplicationProvider(),
      activeTabProvider: ChromeActiveTabProvider(),
      languageProvider: { .english }
    )

    controller.handleModifierChange([.option])
    controller.handleNonModifierKeyPress()

    XCTAssertTrue(controller.isAwaitingModifierRelease)

    controller.handleModifierChange([.option, .shift])
    XCTAssertTrue(controller.isAwaitingModifierRelease)

    controller.handleModifierChange([])
    XCTAssertFalse(controller.isAwaitingModifierRelease)
  }
}
