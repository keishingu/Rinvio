import Foundation
import QuickDrawCore
import XCTest

final class MutePipelineTests: XCTestCase {
  func testTeamsLiveRunDeliversExpectedShortcut() {
    let fixture = makeFixture(bundleIdentifier: "com.microsoft.teams2")

    let report = fixture.pipeline.run(mode: .live)

    XCTAssertEqual(report.outcome.route?.target, .microsoftTeams)
    XCTAssertEqual(fixture.deliverer.shortcuts, [teamsShortcut])
    XCTAssertEqual(fixture.applicationProvider.revalidationCount, 1)
    XCTAssertEqual(fixture.activeTabProvider.queryCount, 0)
  }

  func testZoomLiveRunDeliversExpectedShortcut() {
    let fixture = makeFixture(bundleIdentifier: "us.zoom.xos")

    let report = fixture.pipeline.run(mode: .live)

    XCTAssertEqual(report.outcome.route?.target, .zoomWorkplace)
    XCTAssertEqual(fixture.deliverer.shortcuts, [zoomShortcut])
  }

  func testMeetLiveRunQueriesTabAndDeliversExpectedShortcut() {
    let fixture = makeFixture(
      bundleIdentifier: "com.google.Chrome",
      activeTabURL: URL(string: "https://meet.google.com/abc-defg-hij?authuser=1")!
    )

    let report = fixture.pipeline.run(mode: .live)

    XCTAssertEqual(report.outcome.route?.target, .googleMeet)
    XCTAssertEqual(report.browserClassification, .googleMeet)
    XCTAssertEqual(fixture.activeTabProvider.queryCount, 1)
    XCTAssertEqual(fixture.deliverer.shortcuts, [meetShortcut])
  }

  func testNonBrowserTargetDoesNotQueryActiveTab() {
    let fixture = makeFixture(bundleIdentifier: "com.microsoft.teams2")

    _ = fixture.pipeline.run(mode: .dryRun)

    XCTAssertEqual(fixture.activeTabProvider.queryCount, 0)
  }

  func testDryRunRoutesWithoutRevalidationOrDelivery() {
    let fixture = makeFixture(bundleIdentifier: "us.zoom.xos")

    let report = fixture.pipeline.run(mode: .dryRun)

    XCTAssertEqual(
      report.outcome, .dryRun(MuteRoute(target: .zoomWorkplace, shortcut: zoomShortcut)))
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
    XCTAssertEqual(fixture.applicationProvider.revalidationCount, 0)
  }

  func testChangedTargetPreventsDelivery() {
    let fixture = makeFixture(
      bundleIdentifier: "com.microsoft.teams2",
      isStillForeground: false
    )

    let report = fixture.pipeline.run(mode: .live)

    XCTAssertEqual(report.outcome, .failed(.targetChanged))
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testBrowserProviderFailureIsReportedWithoutDelivery() {
    let fixture = makeFixture(
      bundleIdentifier: "com.google.Chrome",
      activeTabError: TestError.browserUnavailable
    )

    let report = fixture.pipeline.run(mode: .live)

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

    let report = fixture.pipeline.run(mode: .live)

    guard case .failed(.shortcutDeliveryFailed(let message)) = report.outcome else {
      return XCTFail("Expected shortcut delivery failure")
    }
    XCTAssertEqual(message, "Delivery denied")
  }

  func testUnsupportedApplicationFailsWithoutDelivery() {
    let fixture = makeFixture(bundleIdentifier: "com.apple.TextEdit")

    let report = fixture.pipeline.run(mode: .live)

    XCTAssertEqual(
      report.outcome,
      .failed(.routing(.unsupportedApplication(bundleIdentifier: "com.apple.TextEdit")))
    )
    XCTAssertTrue(fixture.deliverer.shortcuts.isEmpty)
  }

  func testMissingForegroundApplicationIsReported() {
    let fixture = makeFixture(bundleIdentifier: nil, hasApplication: false)

    let report = fixture.pipeline.run(mode: .live)

    XCTAssertEqual(report.outcome, .failed(.noForegroundApplication))
    XCTAssertNil(report.application)
  }

  func testReportUsesInjectedClockForLatency() {
    let clock = TestClock(values: [1_000_000, 4_500_000])
    let fixture = makeFixture(
      bundleIdentifier: "us.zoom.xos",
      clock: clock
    )

    let report = fixture.pipeline.run(mode: .dryRun)

    XCTAssertEqual(report.latencyNanoseconds, 3_500_000)
    XCTAssertEqual(report.latencyMilliseconds, 3.5)
  }

  func testDryRunRoutingP95StaysBelow25Milliseconds() {
    let fixture = makeFixture(bundleIdentifier: "us.zoom.xos")
    var latencies = [Double]()

    for _ in 0..<1_000 {
      latencies.append(fixture.pipeline.run(mode: .dryRun).latencyMilliseconds)
    }

    let sorted = latencies.sorted()
    let p95 = sorted[Int(Double(sorted.count - 1) * 0.95)]
    XCTAssertLessThan(p95, 25)
  }

  private var teamsShortcut: KeyStroke {
    KeyStroke(virtualKeyCode: 46, modifiers: [.command, .shift], displayValue: "⌘⇧M")
  }

  private var zoomShortcut: KeyStroke {
    KeyStroke(virtualKeyCode: 0, modifiers: [.command, .shift], displayValue: "⌘⇧A")
  }

  private var meetShortcut: KeyStroke {
    KeyStroke(virtualKeyCode: 2, modifiers: [.command], displayValue: "⌘D")
  }

  private func makeFixture(
    bundleIdentifier: String?,
    hasApplication: Bool = true,
    isStillForeground: Bool = true,
    activeTabURL: URL = URL(string: "https://example.com")!,
    activeTabError: Error? = nil,
    deliveryError: Error? = nil,
    clock: any UptimeProviding = SystemUptimeProvider()
  ) -> Fixture {
    let applicationProvider = TestApplicationProvider(
      application: hasApplication
        ? ApplicationSnapshot(processIdentifier: 42, bundleIdentifier: bundleIdentifier)
        : nil,
      isStillForeground: isStillForeground
    )
    let activeTabProvider = TestActiveTabProvider(url: activeTabURL, error: activeTabError)
    let deliverer = TestShortcutDeliverer(error: deliveryError)
    let pipeline = MutePipeline(
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
  let pipeline: MutePipeline
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

  func foregroundApplication() -> ApplicationSnapshot? {
    application
  }

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
    if let error {
      throw error
    }
    return url
  }
}

private final class TestShortcutDeliverer: ShortcutDelivering {
  let error: Error?
  private(set) var shortcuts: [KeyStroke] = []

  init(error: Error?) {
    self.error = error
  }

  func deliver(_ shortcut: KeyStroke) throws {
    shortcuts.append(shortcut)
    if let error {
      throw error
    }
  }
}

private final class TestClock: UptimeProviding {
  private var values: [UInt64]

  init(values: [UInt64]) {
    self.values = values
  }

  func nowNanoseconds() -> UInt64 {
    values.removeFirst()
  }
}

private enum TestError: LocalizedError {
  case browserUnavailable
  case deliveryDenied

  var errorDescription: String? {
    switch self {
    case .browserUnavailable:
      return "Browser unavailable"
    case .deliveryDenied:
      return "Delivery denied"
    }
  }
}
