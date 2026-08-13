import Foundation
import QuickDrawCore
import XCTest

final class ActionPipelineTests: XCTestCase {
  func testTeamsLiveRunDeliversRequestedAction() {
    let fixture = makeFixture(bundleIdentifier: "com.microsoft.teams2")

    let report = fixture.pipeline.run(action: .camera, mode: .live)

    XCTAssertEqual(report.action, .camera)
    XCTAssertEqual(report.outcome.route?.target, .microsoftTeams)
    XCTAssertEqual(report.outcome.route?.shortcut.displayValue, "⌘⇧O")
    XCTAssertEqual(fixture.deliverer.shortcuts.map(\.displayValue), ["⌘⇧O"])
    XCTAssertEqual(fixture.applicationProvider.revalidationCount, 1)
    XCTAssertEqual(fixture.activeTabProvider.queryCount, 0)
  }

  func testZoomLiveRunDeliversRequestedAction() {
    let fixture = makeFixture(bundleIdentifier: "us.zoom.xos")

    let report = fixture.pipeline.run(action: .raiseHand, mode: .live)

    XCTAssertEqual(report.outcome.route?.target, .zoomWorkplace)
    XCTAssertEqual(fixture.deliverer.shortcuts.map(\.displayValue), ["⌥Y"])
  }

  func testMeetLiveRunQueriesTabAndDeliversRequestedAction() {
    let fixture = makeFixture(
      bundleIdentifier: "com.google.Chrome",
      activeTabURL: URL(string: "https://meet.google.com/abc-defg-hij?authuser=1")!
    )

    let report = fixture.pipeline.run(action: .camera, mode: .live)

    XCTAssertEqual(report.outcome.route?.target, .googleMeet)
    XCTAssertEqual(report.browserClassification, .googleMeet)
    XCTAssertEqual(fixture.activeTabProvider.queryCount, 1)
    XCTAssertEqual(fixture.deliverer.shortcuts.map(\.displayValue), ["⌘E"])
  }

  func testGmailLiveRunQueriesTabAndDeliversRequestedAction() {
    let fixture = makeFixture(
      bundleIdentifier: "com.google.Chrome",
      activeTabURL: URL(string: "https://mail.google.com/mail/u/0/#inbox")!
    )

    let report = fixture.pipeline.run(action: .searchAllEmail, mode: .live)

    XCTAssertEqual(report.outcome.route?.target, .gmail)
    XCTAssertEqual(report.browserClassification, .gmail)
    XCTAssertEqual(fixture.activeTabProvider.queryCount, 1)
    XCTAssertEqual(fixture.deliverer.shortcuts.map(\.displayValue), ["/"])
  }

  func testNonBrowserTargetDoesNotQueryActiveTab() {
    let fixture = makeFixture(bundleIdentifier: "com.microsoft.teams2")

    _ = fixture.pipeline.run(action: .mute, mode: .dryRun)

    XCTAssertEqual(fixture.activeTabProvider.queryCount, 0)
  }

  func testChromeHardReloadDoesNotQueryActiveTab() {
    let fixture = makeFixture(
      bundleIdentifier: "com.google.Chrome",
      activeTabError: TestError.browserUnavailable
    )

    let report = fixture.pipeline.run(action: .hardReload, mode: .live)

    XCTAssertEqual(report.outcome.route?.target, .googleChrome)
    XCTAssertEqual(report.outcome.route?.shortcut.displayValue, "⌘⇧R")
    XCTAssertEqual(fixture.activeTabProvider.queryCount, 0)
    XCTAssertEqual(fixture.deliverer.shortcuts.map(\.displayValue), ["⌘⇧R"])
  }

  func testDryRunRoutesWithoutRevalidationOrDelivery() {
    let fixture = makeFixture(bundleIdentifier: "us.zoom.xos")

    let report = fixture.pipeline.run(action: .mute, mode: .dryRun)

    XCTAssertEqual(report.outcome.route?.shortcut.displayValue, "⌘⇧A")
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
    XCTAssertEqual(fixture.applicationProvider.revalidationCount, 0)
  }

  func testChangedTargetPreventsDelivery() {
    let fixture = makeFixture(
      bundleIdentifier: "com.microsoft.teams2",
      isStillForeground: false
    )

    let report = fixture.pipeline.run(action: .mute, mode: .live)

    XCTAssertEqual(report.outcome, .failed(.targetChanged))
    XCTAssertFalse(report.outcome.consumesTrigger)
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testBrowserProviderFailureIsReportedWithoutDelivery() {
    let fixture = makeFixture(
      bundleIdentifier: "com.google.Chrome",
      activeTabError: TestError.browserUnavailable
    )

    let report = fixture.pipeline.run(action: .raiseHand, mode: .live)

    XCTAssertEqual(report.browserClassification, .unavailable)
    guard case .failed(.browserContextUnavailable(let message)) = report.outcome else {
      return XCTFail("Expected browser context failure")
    }
    XCTAssertEqual(message, "Browser unavailable")
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testDeliveryFailureIsReported() {
    let fixture = makeFixture(
      bundleIdentifier: "us.zoom.xos",
      deliveryError: TestError.deliveryDenied
    )

    let report = fixture.pipeline.run(action: .camera, mode: .live)

    guard case .failed(.shortcutDeliveryFailed(let message)) = report.outcome else {
      return XCTFail("Expected shortcut delivery failure")
    }
    XCTAssertEqual(message, "Delivery denied")
    XCTAssertFalse(report.outcome.consumesTrigger)
  }

  func testUnsupportedApplicationFailsWithoutDelivery() {
    let fixture = makeFixture(bundleIdentifier: "com.apple.TextEdit")

    let report = fixture.pipeline.run(action: .mute, mode: .live)

    XCTAssertEqual(
      report.outcome,
      .failed(.routing(.unsupportedApplication(bundleIdentifier: "com.apple.TextEdit")))
    )
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
    XCTAssertFalse(report.outcome.consumesTrigger)
  }

  func testUnsupportedActionFailsWithoutDelivery() {
    let fixture = makeFixture(bundleIdentifier: "com.microsoft.teams2")

    let report = fixture.pipeline.run(action: .reactionHeart, mode: .live)

    XCTAssertEqual(
      report.outcome,
      .failed(.routing(.unsupportedAction(action: .reactionHeart, target: .microsoftTeams)))
    )
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
    XCTAssertEqual(fixture.applicationProvider.revalidationCount, 0)
    XCTAssertFalse(report.outcome.consumesTrigger)
  }

  func testJetBrainsF6PassesThroughWhenRegionNavigationIsUnsupported() {
    let fixture = makeFixture(bundleIdentifier: "com.google.android.studio")

    let report = fixture.pipeline.run(action: .focusNextRegion, mode: .live)

    XCTAssertEqual(
      report.outcome,
      .failed(.routing(.unsupportedAction(action: .focusNextRegion, target: .androidStudio)))
    )
    XCTAssertFalse(report.outcome.consumesTrigger)
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testDisabledApplicationPassesTriggerThroughWithoutDelivery() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    try store.setApplicationEnabled(false, for: .zoomWorkplace)
    let router = ActionRouter(
      overrideProvider: store,
      applicationEnablementProvider: store
    )
    let fixture = makeFixture(bundleIdentifier: "us.zoom.xos", router: router)

    let report = fixture.pipeline.run(action: .mute, mode: .live)

    XCTAssertEqual(
      report.outcome,
      .failed(.routing(.disabledApplication(target: .zoomWorkplace)))
    )
    XCTAssertFalse(report.outcome.consumesTrigger)
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testFinderEnabledRoutesOnlyWhileFinderIsForeground() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    try store.setApplicationEnabled(true, for: .finder)
    let router = ActionRouter(
      overrideProvider: store,
      applicationEnablementProvider: store
    )
    let finder = makeFixture(bundleIdentifier: "com.apple.finder", router: router)
    let otherApplication = makeFixture(bundleIdentifier: "com.apple.TextEdit", router: router)

    for action in [
      Action.finderParentFolder, .finderOpenSelectedItem, .finderHome, .finderDesktop,
      .finderDownloads,
    ] {
      let finderReport = finder.pipeline.run(action: action, mode: .live)
      XCTAssertEqual(finderReport.outcome.route?.target, .finder)
    }
    let otherReport = otherApplication.pipeline.run(action: .finderParentFolder, mode: .live)

    XCTAssertEqual(
      finder.deliverer.shortcuts.map(\.displayValue),
      ["⌘↑", "⌘↓", "⇧⌘H", "⇧⌘D", "⌘⌥L"]
    )
    XCTAssertFalse(otherReport.outcome.consumesTrigger)
    XCTAssertTrue(otherApplication.deliverer.shortcuts.isEmpty)
  }

  func testFinderDisabledPassesThroughEvenWhileFinderIsForeground() {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let router = ActionRouter(
      overrideProvider: store,
      applicationEnablementProvider: store
    )
    let fixture = makeFixture(bundleIdentifier: "com.apple.finder", router: router)

    let report = fixture.pipeline.run(action: .finderOpenSelectedItem, mode: .live)

    XCTAssertEqual(report.outcome, .failed(.routing(.disabledApplication(target: .finder))))
    XCTAssertFalse(report.outcome.consumesTrigger)
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testMacOSDisabledPassesCommandArrowThrough() {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    let router = ActionRouter(
      overrideProvider: store,
      applicationEnablementProvider: store
    )
    let fixture = makeFixture(bundleIdentifier: "com.apple.TextEdit", router: router)

    let report = fixture.pipeline.run(action: .missionControl, mode: .live)

    XCTAssertEqual(report.outcome, .failed(.routing(.disabledApplication(target: .macOS))))
    XCTAssertFalse(report.outcome.consumesTrigger)
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testMacOSRemainsPassThroughWhenEnablementIsRequested() throws {
    let store = QuickDrawConfigurationStore(fileURL: nil)
    try store.setApplicationEnabled(true, for: .macOS)
    let router = ActionRouter(
      overrideProvider: store,
      applicationEnablementProvider: store
    )
    let fixture = makeFixture(bundleIdentifier: "com.apple.TextEdit", router: router)

    for action in Action.allCases where ActionCatalog.isSystemWide(action) {
      let report = fixture.pipeline.run(action: action, mode: .live)
      XCTAssertEqual(report.outcome, .failed(.routing(.disabledApplication(target: .macOS))))
      XCTAssertFalse(report.outcome.consumesTrigger)
    }
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testActionFromInactiveDomainPassesTriggerThrough() {
    let fixture = makeFixture(bundleIdentifier: "com.tinyspeck.slackmacgap")

    let report = fixture.pipeline.run(action: .leaveMeeting, mode: .live)

    XCTAssertEqual(
      report.outcome,
      .failed(.routing(.inactiveDomain(domain: .meeting, target: .slack)))
    )
    XCTAssertFalse(report.outcome.consumesTrigger)
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testNonMeetChromePagePassesTriggerThrough() {
    let fixture = makeFixture(
      bundleIdentifier: "com.google.Chrome",
      activeTabURL: URL(string: "https://example.com")!
    )

    let report = fixture.pipeline.run(action: .mute, mode: .live)

    XCTAssertFalse(report.outcome.consumesTrigger)
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testMissingForegroundApplicationIsReported() {
    let fixture = makeFixture(bundleIdentifier: nil, hasApplication: false)

    let report = fixture.pipeline.run(action: .mute, mode: .live)

    XCTAssertEqual(report.outcome, .failed(.noForegroundApplication))
    XCTAssertNil(report.application)
  }

  func testReportUsesInjectedClockForLatency() {
    let fixture = makeFixture(
      bundleIdentifier: "us.zoom.xos",
      clock: TestClock(values: [1_000_000, 4_500_000])
    )

    let report = fixture.pipeline.run(action: .mute, mode: .dryRun)

    XCTAssertEqual(report.latencyNanoseconds, 3_500_000)
    XCTAssertEqual(report.latencyMilliseconds, 3.5)
  }

  func testDryRunRoutingP95StaysBelow25Milliseconds() {
    let fixture = makeFixture(bundleIdentifier: "us.zoom.xos")
    var latencies = [Double]()

    for _ in 0..<1_000 {
      latencies.append(
        fixture.pipeline.run(action: .raiseHand, mode: .dryRun).latencyMilliseconds
      )
    }

    let sorted = latencies.sorted()
    let p95 = sorted[Int(Double(sorted.count - 1) * 0.95)]
    XCTAssertLessThan(p95, 25)
  }

  private func makeFixture(
    bundleIdentifier: String?,
    hasApplication: Bool = true,
    isStillForeground: Bool = true,
    activeTabURL: URL = URL(string: "https://example.com")!,
    activeTabError: Error? = nil,
    deliveryError: Error? = nil,
    clock: any UptimeProviding = SystemUptimeProvider(),
    router: ActionRouter = ActionRouter()
  ) -> Fixture {
    let applicationProvider = TestApplicationProvider(
      application: hasApplication
        ? ApplicationSnapshot(processIdentifier: 42, bundleIdentifier: bundleIdentifier)
        : nil,
      isStillForeground: isStillForeground
    )
    let activeTabProvider = TestActiveTabProvider(url: activeTabURL, error: activeTabError)
    let deliverer = TestShortcutDeliverer(error: deliveryError)
    let pipeline = ActionPipeline(
      router: router,
      applicationProvider: applicationProvider,
      activeTabProvider: activeTabProvider,
      shortcutDeliverer: deliverer,
      uptimeProvider: clock
    )
    return Fixture(
      pipeline: pipeline,
      applicationProvider: applicationProvider,
      activeTabProvider: activeTabProvider,
      deliverer: deliverer
    )
  }
}

private struct Fixture {
  let pipeline: ActionPipeline
  let applicationProvider: TestApplicationProvider
  let activeTabProvider: TestActiveTabProvider
  let deliverer: TestShortcutDeliverer
}

private final class TestApplicationProvider: ForegroundApplicationProviding {
  let application: ApplicationSnapshot?
  let shouldRemainForeground: Bool
  private(set) var revalidationCount = 0

  init(application: ApplicationSnapshot?, isStillForeground: Bool) {
    self.application = application
    shouldRemainForeground = isStillForeground
  }

  func foregroundApplication() -> ApplicationSnapshot? { application }

  func isStillForeground(_ application: ApplicationSnapshot) -> Bool {
    revalidationCount += 1
    return shouldRemainForeground
  }
}

private final class TestActiveTabProvider: ActiveTabURLProviding {
  let url: URL
  let error: Error?
  private(set) var queryCount = 0

  init(url: URL, error: Error?) {
    self.url = url
    self.error = error
  }

  func activeTabURL() throws -> URL {
    queryCount += 1
    if let error { throw error }
    return url
  }
}

private final class TestShortcutDeliverer: ShortcutDelivering {
  let error: Error?
  private(set) var shortcuts: [KeyStroke] = []

  init(error: Error?) { self.error = error }

  func deliver(_ shortcut: KeyStroke) throws {
    shortcuts.append(shortcut)
    if let error { throw error }
  }
}

private final class TestClock: UptimeProviding {
  private var values: [UInt64]

  init(values: [UInt64]) { self.values = values }

  func nowNanoseconds() -> UInt64 { values.removeFirst() }
}

private enum TestError: LocalizedError {
  case browserUnavailable
  case deliveryDenied

  var errorDescription: String? {
    switch self {
    case .browserUnavailable: "Browser unavailable"
    case .deliveryDenied: "Delivery denied"
    }
  }
}
