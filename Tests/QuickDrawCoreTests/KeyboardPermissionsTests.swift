import XCTest

@testable import QuickDrawShortcuts

final class KeyboardPermissionsTests: XCTestCase {
  func testInputMonitoringAuthorizerKeepsPreflightAndRequestSeparate() {
    var requestCount = 0
    let authorizer = InputMonitoringAuthorizer(
      preflight: { false },
      request: {
        requestCount += 1
        return true
      }
    )

    XCTAssertFalse(authorizer.hasAccess)
    XCTAssertTrue(authorizer.requestAccess())
    XCTAssertEqual(requestCount, 1)
  }

  func testBothKeyboardPermissionsAreRequiredForFullAuthorization() {
    XCTAssertFalse(
      KeyboardPermissionState(
        hasInputMonitoringAccess: false,
        hasPostEventAccess: true
      ).isFullyAuthorized
    )
    XCTAssertFalse(
      KeyboardPermissionState(
        hasInputMonitoringAccess: true,
        hasPostEventAccess: false
      ).isFullyAuthorized
    )
    XCTAssertTrue(
      KeyboardPermissionState(
        hasInputMonitoringAccess: true,
        hasPostEventAccess: true
      ).isFullyAuthorized
    )
  }
}
