import Foundation
import QuickDrawCore
import XCTest

@testable import QuickDrawShortcuts

final class ActionControllerTests: XCTestCase {
  func testDeliveryFailurePassesThroughAndRemainsVisibleInDiagnostics() {
    let pipeline = ActionPipeline(
      applicationProvider: StaticApplicationProvider(),
      activeTabProvider: UnusedActiveTabProvider(),
      shortcutDeliverer: FailingShortcutDeliverer()
    )
    let controller = ActionController(
      pipeline: pipeline,
      shortcutExecutor: ShortcutExecutor(),
      inputMonitoringAuthorizer: InputMonitoringAuthorizer(
        preflight: { true },
        request: { true }
      )
    )
    var status: ActionStatus?
    controller.onStatusChange = { status = $0 }

    let consumed = controller.trigger(.camera)

    XCTAssertFalse(consumed)
    XCTAssertEqual(status?.headline, "Camera not delivered")
    XCTAssertTrue(controller.diagnosticsText().contains("Delivery denied"))
  }
}

private struct StaticApplicationProvider: ForegroundApplicationProviding {
  func foregroundApplication() -> ApplicationSnapshot? {
    ApplicationSnapshot(processIdentifier: 1, bundleIdentifier: "us.zoom.xos")
  }

  func isStillForeground(_ application: ApplicationSnapshot) -> Bool { true }
}

private struct UnusedActiveTabProvider: ActiveTabURLProviding {
  func activeTabURL() throws -> URL {
    XCTFail("Zoom routing must not query browser context")
    return URL(string: "https://example.com")!
  }
}

private struct FailingShortcutDeliverer: ShortcutDelivering {
  func deliver(_ shortcut: KeyStroke) throws {
    throw TestDeliveryError.denied
  }
}

private enum TestDeliveryError: LocalizedError {
  case denied

  var errorDescription: String? { "Delivery denied" }
}
