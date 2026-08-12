import QuickDrawCore
import XCTest

@testable import QuickDrawPoC

@MainActor
final class ShortcutCheatSheetControllerTests: XCTestCase {
  private struct MailForegroundProvider: ForegroundApplicationProviding {
    func foregroundApplication() -> ApplicationSnapshot? {
      ApplicationSnapshot(processIdentifier: 1, bundleIdentifier: "com.apple.mail")
    }

    func isStillForeground(_ application: ApplicationSnapshot) -> Bool { true }
  }

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

  func testModifierReleaseKeepsExplicitPreviewVisible() {
    let controller = ShortcutCheatSheetController(
      configurationStore: QuickDrawConfigurationStore(fileURL: nil),
      foregroundProvider: MailForegroundProvider(),
      activeTabProvider: ChromeActiveTabProvider(),
      languageProvider: { .english }
    )

    controller.handleModifierChange([.option])
    controller.handleNonModifierKeyPress()
    controller.presentPreview()
    XCTAssertTrue(controller.isPreviewVisible)

    controller.handleModifierChange([])

    XCTAssertTrue(controller.isPreviewVisible)
    controller.reset()
  }
}
