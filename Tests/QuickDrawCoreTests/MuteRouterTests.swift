import Foundation
import QuickDrawCore
import XCTest

final class MuteRouterTests: XCTestCase {
  private let router = MuteRouter()

  func testRoutesNewTeamsToCommandShiftM() throws {
    let route = try route(bundleIdentifier: "com.microsoft.teams2")

    XCTAssertEqual(route.target, .microsoftTeams)
    XCTAssertEqual(route.shortcut.virtualKeyCode, 46)
    XCTAssertEqual(route.shortcut.modifiers, [.command, .shift])
    XCTAssertEqual(route.shortcut.displayValue, "⌘⇧M")
  }

  func testRoutesLegacyTeamsToCommandShiftM() throws {
    XCTAssertEqual(
      try route(bundleIdentifier: "com.microsoft.teams").target,
      .microsoftTeams
    )
  }

  func testRoutesZoomToCommandShiftA() throws {
    let route = try route(bundleIdentifier: "us.zoom.xos")

    XCTAssertEqual(route.target, .zoomWorkplace)
    XCTAssertEqual(route.shortcut.virtualKeyCode, 0)
    XCTAssertEqual(route.shortcut.modifiers, [.command, .shift])
    XCTAssertEqual(route.shortcut.displayValue, "⌘⇧A")
  }

  func testRoutesHTTPSMeetTabToCommandD() throws {
    let route = try route(
      bundleIdentifier: "com.google.Chrome",
      activeTabURL: URL(string: "https://meet.google.com/abc-defg-hij?authuser=1")
    )

    XCTAssertEqual(route.target, .googleMeet)
    XCTAssertEqual(route.shortcut.virtualKeyCode, 2)
    XCTAssertEqual(route.shortcut.modifiers, [.command])
    XCTAssertEqual(route.shortcut.displayValue, "⌘D")
  }

  func testRejectsLookalikeMeetHost() {
    assertFailure(
      bundleIdentifier: "com.google.Chrome",
      activeTabURL: URL(string: "https://meet.google.com.example.test/"),
      expected: .unsupportedWebPage(host: "meet.google.com.example.test")
    )
  }

  func testRejectsInsecureMeetURL() {
    assertFailure(
      bundleIdentifier: "com.google.Chrome",
      activeTabURL: URL(string: "http://meet.google.com/abc"),
      expected: .unsupportedWebPage(host: "meet.google.com")
    )
  }

  func testRejectsNonMeetChromeTab() {
    assertFailure(
      bundleIdentifier: "com.google.Chrome",
      activeTabURL: URL(string: "https://example.com/"),
      expected: .unsupportedWebPage(host: "example.com")
    )
  }

  func testUnsupportedWebPageMessageDoesNotExposeHost() {
    let failure = MuteRoutingFailure.unsupportedWebPage(host: "private.example.com")

    XCTAssertEqual(failure.userMessage, "Active Chrome tab is not Google Meet")
    XCTAssertFalse(failure.userMessage.contains("private.example.com"))
  }

  func testReportsMissingBrowserContext() {
    assertFailure(
      bundleIdentifier: "com.google.Chrome",
      activeTabURL: nil,
      expected: .browserContextUnavailable
    )
  }

  func testRejectsUnsupportedApplication() {
    assertFailure(
      bundleIdentifier: "com.apple.TextEdit",
      activeTabURL: nil,
      expected: .unsupportedApplication(bundleIdentifier: "com.apple.TextEdit")
    )
  }

  func testReportsMissingBundleIdentifier() {
    assertFailure(
      bundleIdentifier: nil,
      activeTabURL: nil,
      expected: .missingBundleIdentifier
    )
  }

  private func route(bundleIdentifier: String, activeTabURL: URL? = nil) throws -> MuteRoute {
    try router.route(
      ForegroundContext(
        bundleIdentifier: bundleIdentifier,
        activeTabURL: activeTabURL
      )
    ).get()
  }

  private func assertFailure(
    bundleIdentifier: String?,
    activeTabURL: URL?,
    expected: MuteRoutingFailure,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let result = router.route(
      ForegroundContext(
        bundleIdentifier: bundleIdentifier,
        activeTabURL: activeTabURL
      )
    )
    guard case .failure(let actual) = result else {
      XCTFail("Expected routing failure", file: file, line: line)
      return
    }
    XCTAssertEqual(actual, expected, file: file, line: line)
  }
}
