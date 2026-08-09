import Foundation
import QuickDrawCore
import XCTest

final class ActionRouterTests: XCTestCase {
  private let router = ActionRouter()

  func testRoutesAllLevelOneActionsForTeams() throws {
    try assertRoute(
      .mute, bundleIdentifier: "com.microsoft.teams2", keyCode: 46, modifiers: [.command, .shift],
      display: "⌘⇧M")
    try assertRoute(
      .camera, bundleIdentifier: "com.microsoft.teams2", keyCode: 31,
      modifiers: [.command, .shift], display: "⌘⇧O")
    try assertRoute(
      .raiseHand, bundleIdentifier: "com.microsoft.teams2", keyCode: 40,
      modifiers: [.command, .shift], display: "⌘⇧K")
  }

  func testRoutesLegacyTeams() throws {
    XCTAssertEqual(
      try route(.mute, bundleIdentifier: "com.microsoft.teams").target,
      .microsoftTeams
    )
  }

  func testRoutesAllLevelOneActionsForZoom() throws {
    try assertRoute(
      .mute, bundleIdentifier: "us.zoom.xos", keyCode: 0, modifiers: [.command, .shift],
      display: "⌘⇧A")
    try assertRoute(
      .camera, bundleIdentifier: "us.zoom.xos", keyCode: 9, modifiers: [.command, .shift],
      display: "⌘⇧V")
    try assertRoute(
      .raiseHand, bundleIdentifier: "us.zoom.xos", keyCode: 16, modifiers: [.option], display: "⌥Y")
  }

  func testRoutesAllLevelOneActionsForMeet() throws {
    let url = URL(string: "https://meet.google.com/abc-defg-hij?authuser=1")
    try assertRoute(
      .mute, bundleIdentifier: "com.google.Chrome", activeTabURL: url, keyCode: 2,
      modifiers: [.command], display: "⌘D")
    try assertRoute(
      .camera, bundleIdentifier: "com.google.Chrome", activeTabURL: url, keyCode: 14,
      modifiers: [.command], display: "⌘E")
    try assertRoute(
      .raiseHand, bundleIdentifier: "com.google.Chrome", activeTabURL: url, keyCode: 4,
      modifiers: [.command, .control], display: "⌃⌘H")
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
    let failure = ActionRoutingFailure.unsupportedWebPage(host: "private.example.com")

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
    assertFailure(bundleIdentifier: nil, activeTabURL: nil, expected: .missingBundleIdentifier)
  }

  func testUsesApplicationShortcutOverride() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let override = KeyStroke(
      virtualKeyCode: 11,
      modifiers: [.command, .option],
      displayValue: "⌥⌘B"
    )
    try store.setShortcutOverride(override, for: .camera, target: .zoomWorkplace)
    let router = ActionRouter(overrideProvider: store)

    let route = try router.route(
      action: .camera,
      context: ForegroundContext(bundleIdentifier: "us.zoom.xos")
    ).get()

    XCTAssertEqual(route.shortcut, override)
  }

  private func assertRoute(
    _ action: MeetingAction,
    bundleIdentifier: String,
    activeTabURL: URL? = nil,
    keyCode: UInt16,
    modifiers: Set<ModifierKey>,
    display: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    let result = try route(action, bundleIdentifier: bundleIdentifier, activeTabURL: activeTabURL)
    XCTAssertEqual(result.action, action, file: file, line: line)
    XCTAssertEqual(result.shortcut.virtualKeyCode, keyCode, file: file, line: line)
    XCTAssertEqual(result.shortcut.modifiers, modifiers, file: file, line: line)
    XCTAssertEqual(result.shortcut.displayValue, display, file: file, line: line)
  }

  private func route(
    _ action: MeetingAction,
    bundleIdentifier: String,
    activeTabURL: URL? = nil
  ) throws -> ActionRoute {
    try router.route(
      action: action,
      context: ForegroundContext(
        bundleIdentifier: bundleIdentifier,
        activeTabURL: activeTabURL
      )
    ).get()
  }

  private func assertFailure(
    bundleIdentifier: String?,
    activeTabURL: URL?,
    expected: ActionRoutingFailure,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let result = router.route(
      action: .mute,
      context: ForegroundContext(
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
