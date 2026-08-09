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

  func testRoutesExpandedMeetingActions() throws {
    try assertRoute(
      .toggleCaptions, bundleIdentifier: "com.microsoft.teams2", keyCode: 0,
      modifiers: [.command, .shift], display: "⌘⇧A")
    try assertRoute(
      .shareScreen, bundleIdentifier: "com.microsoft.teams2", keyCode: 14,
      modifiers: [.command, .shift], display: "⌘⇧E")
    try assertRoute(
      .leaveMeeting, bundleIdentifier: "com.microsoft.teams2", keyCode: 4,
      modifiers: [.command, .shift], display: "⌘⇧H")

    try assertRoute(
      .openChat, bundleIdentifier: "us.zoom.xos", keyCode: 4,
      modifiers: [.command, .shift], display: "⌘⇧H")
    try assertRoute(
      .showParticipants, bundleIdentifier: "us.zoom.xos", keyCode: 32,
      modifiers: [.command], display: "⌘U")
    try assertRoute(
      .switchCamera, bundleIdentifier: "us.zoom.xos", keyCode: 45,
      modifiers: [.command, .shift], display: "⌘⇧N")
    try assertRoute(
      .leaveMeeting, bundleIdentifier: "us.zoom.xos", keyCode: 13,
      modifiers: [.command], display: "⌘W")
    try assertRoute(
      .reactionLike, bundleIdentifier: "us.zoom.xos", keyCode: 23,
      modifiers: [.command, .option], display: "⌥⌘5")
    try assertRoute(
      .reactionCelebrate, bundleIdentifier: "us.zoom.xos", keyCode: 25,
      modifiers: [.command, .option], display: "⌥⌘9")

    let meetURL = URL(string: "https://meet.google.com/abc-defg-hij")
    try assertRoute(
      .openChat, bundleIdentifier: "com.google.Chrome", activeTabURL: meetURL, keyCode: 8,
      modifiers: [.command, .control], display: "⌃⌘C")
    try assertRoute(
      .showParticipants, bundleIdentifier: "com.google.Chrome", activeTabURL: meetURL, keyCode: 35,
      modifiers: [.command, .control], display: "⌃⌘P")
    try assertRoute(
      .shareScreen, bundleIdentifier: "com.google.Chrome", activeTabURL: meetURL, keyCode: 17,
      modifiers: [.command, .control], display: "⌃⌘T")
    try assertRoute(
      .pictureInPicture, bundleIdentifier: "com.google.Chrome", activeTabURL: meetURL,
      keyCode: 46, modifiers: [.shift], display: "⇧M")
    try assertRoute(
      .leaveMeeting, bundleIdentifier: "com.google.Chrome", activeTabURL: meetURL,
      keyCode: 33, modifiers: [.command], display: "⌘[")
  }

  func testRoutesNewSessionForDevelopmentAgents() throws {
    try assertRoute(
      .newSession, bundleIdentifier: "com.openai.codex", keyCode: 45,
      modifiers: [.command], display: "⌘N")
    try assertRoute(
      .newSession, bundleIdentifier: "com.anthropic.claudefordesktop", keyCode: 45,
      modifiers: [.command], display: "⌘N")
  }

  func testRoutesDevelopmentToolActions() throws {
    try assertRoute(
      .toggleTerminal, bundleIdentifier: "com.openai.codex", keyCode: 50,
      modifiers: [.control], display: "⌃`")
    try assertRoute(
      .commandPalette, bundleIdentifier: "com.openai.codex", keyCode: 40,
      modifiers: [.command], display: "⌘K")
    try assertRoute(
      .quickOpen, bundleIdentifier: "com.openai.codex", keyCode: 35,
      modifiers: [.command], display: "⌘P")
    try assertRoute(
      .showKeyboardShortcuts, bundleIdentifier: "com.openai.codex", keyCode: 44,
      modifiers: [.command], display: "⌘/")
    try assertRoute(
      .focusTerminal, bundleIdentifier: "com.openai.codex", keyCode: 50,
      modifiers: [.control], display: "⌃`")

    for bundleIdentifier in ["com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92"] {
      try assertRoute(
        .toggleTerminal, bundleIdentifier: bundleIdentifier, keyCode: 50,
        modifiers: [.control], display: "⌃`")
      try assertRoute(
        .newTerminal, bundleIdentifier: bundleIdentifier, keyCode: 50,
        modifiers: [.control, .shift], display: "⌃⇧`")
      try assertRoute(
        .commandPalette, bundleIdentifier: bundleIdentifier, keyCode: 35,
        modifiers: [.command, .shift], display: "⌘⇧P")
      try assertRoute(
        .quickOpen, bundleIdentifier: bundleIdentifier, keyCode: 35,
        modifiers: [.command], display: "⌘P")
      try assertRoute(
        .nextTerminal, bundleIdentifier: bundleIdentifier, keyCode: 30,
        modifiers: [.command, .shift], display: "⇧⌘]")
      try assertRoute(
        .previousTerminal, bundleIdentifier: bundleIdentifier, keyCode: 33,
        modifiers: [.command, .shift], display: "⇧⌘[")
      try assertRoute(
        .splitTerminal, bundleIdentifier: bundleIdentifier, keyCode: 42,
        modifiers: [.command], display: "⌘\\")
      try assertRoute(
        .focusSidebar, bundleIdentifier: bundleIdentifier, keyCode: 29,
        modifiers: [.command], display: "⌘0")
      try assertRoute(
        .focusMainColumn, bundleIdentifier: bundleIdentifier, keyCode: 18,
        modifiers: [.command], display: "⌘1")
      try assertRoute(
        .focusTerminal, bundleIdentifier: bundleIdentifier, keyCode: 50,
        modifiers: [.control], display: "⌃`")
    }

    try assertRoute(
      .nextTerminal, bundleIdentifier: "com.apple.Terminal", keyCode: 48,
      modifiers: [.control], display: "⌃Tab")
    try assertRoute(
      .previousTerminal, bundleIdentifier: "com.apple.Terminal", keyCode: 48,
      modifiers: [.control, .shift], display: "⌃⇧Tab")
    try assertRoute(
      .splitTerminal, bundleIdentifier: "com.apple.Terminal", keyCode: 2,
      modifiers: [.command], display: "⌘D")
    try assertRoute(
      .splitTerminal, bundleIdentifier: "com.googlecode.iterm2", keyCode: 2,
      modifiers: [.command], display: "⌘D")
  }

  func testRoutesHardReloadWithoutWebApplicationDetection() throws {
    try assertRoute(
      .hardReload, bundleIdentifier: "com.apple.Safari", keyCode: 15,
      modifiers: [.command, .option], display: "⌘⌥R")
    try assertRoute(
      .hardReload, bundleIdentifier: "com.google.Chrome", keyCode: 15,
      modifiers: [.command, .shift], display: "⌘⇧R")
  }

  func testRoutesBrowserNavigationAndTools() throws {
    try assertRoute(
      .nextTab, bundleIdentifier: "com.apple.Safari", keyCode: 48,
      modifiers: [.control], display: "⌃Tab")
    try assertRoute(
      .nextTab, bundleIdentifier: "com.google.Chrome", keyCode: 124,
      modifiers: [.command, .option], display: "⌘⌥→")
    try assertRoute(
      .previousTab, bundleIdentifier: "com.apple.Safari", keyCode: 48,
      modifiers: [.control, .shift], display: "⌃⇧Tab")
    try assertRoute(
      .previousTab, bundleIdentifier: "com.google.Chrome", keyCode: 123,
      modifiers: [.command, .option], display: "⌘⌥←")
    try assertRoute(
      .openDownloads, bundleIdentifier: "com.apple.Safari", keyCode: 37,
      modifiers: [.command, .option], display: "⌘⌥L")
    try assertRoute(
      .openDownloads, bundleIdentifier: "com.google.Chrome", keyCode: 38,
      modifiers: [.command, .shift], display: "⌘⇧J")
    try assertRoute(
      .openDeveloperTools, bundleIdentifier: "com.apple.Safari", keyCode: 34,
      modifiers: [.command, .option], display: "⌘⌥I")
    try assertRoute(
      .openDeveloperTools, bundleIdentifier: "com.google.Chrome", keyCode: 34,
      modifiers: [.command, .option], display: "⌘⌥I")
    try assertRoute(
      .reopenClosedTab, bundleIdentifier: "com.apple.Safari", keyCode: 17,
      modifiers: [.command, .shift], display: "⌘⇧T")
    try assertRoute(
      .reopenClosedTab, bundleIdentifier: "com.google.Chrome", keyCode: 17,
      modifiers: [.command, .shift], display: "⌘⇧T")
  }

  func testUnsupportedActionFailsWithoutShortcut() {
    assertFailure(
      action: .reactionLike,
      bundleIdentifier: "com.microsoft.teams2",
      activeTabURL: nil,
      expected: .unsupportedAction(action: .reactionLike, target: .microsoftTeams)
    )
  }

  func testEveryCatalogActionHasAtLeastOneBuiltInApplicationShortcut() {
    for action in Action.allCases {
      XCTAssertTrue(
        ActionTarget.allCases.contains {
          ActionCatalog.defaultShortcut(for: action, target: $0) != nil
        },
        "\(action.rawValue) must have at least one built-in application shortcut"
      )
    }
  }

  func testAllZoomReactionShortcuts() throws {
    let expected: [(Action, UInt16, String)] = [
      (.reactionClap, 21, "⌥⌘4"),
      (.reactionLike, 23, "⌥⌘5"),
      (.reactionHeart, 22, "⌥⌘6"),
      (.reactionLaugh, 26, "⌥⌘7"),
      (.reactionWow, 28, "⌥⌘8"),
      (.reactionCelebrate, 25, "⌥⌘9"),
    ]

    for (action, keyCode, display) in expected {
      try assertRoute(
        action,
        bundleIdentifier: "us.zoom.xos",
        keyCode: keyCode,
        modifiers: [.command, .option],
        display: display
      )
    }
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

  func testOverrideCanAddShortcutForUnsupportedApplicationAction() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let override = KeyStroke(
      virtualKeyCode: 23,
      modifiers: [.command, .option],
      displayValue: "⌥⌘5"
    )
    try store.setShortcutOverride(override, for: .reactionLike, target: .microsoftTeams)
    let router = ActionRouter(overrideProvider: store)

    let route = try router.route(
      action: .reactionLike,
      context: ForegroundContext(bundleIdentifier: "com.microsoft.teams2")
    ).get()

    XCTAssertEqual(route.shortcut, override)
  }

  private func assertRoute(
    _ action: Action,
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
    _ action: Action,
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
    action: Action = .mute,
    bundleIdentifier: String?,
    activeTabURL: URL?,
    expected: ActionRoutingFailure,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let result = router.route(
      action: action,
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
