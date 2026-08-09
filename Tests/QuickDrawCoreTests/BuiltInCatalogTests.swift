import Foundation
import QuickDrawCore
import XCTest

final class BuiltInCatalogTests: XCTestCase {
  func testBundledCatalogDefinesEveryActionAndApplication() throws {
    for action in Action.allCases {
      XCTAssertNotNil(ActionCatalog.defaultTrigger(for: action))
      XCTAssertTrue(
        ActionTarget.allCases.contains {
          ActionCatalog.defaultShortcut(for: action, target: $0) != nil
        }
      )
    }

    for target in ActionTarget.allCases {
      XCTAssertEqual(ActionCatalog.application(for: target).target, target)
    }
  }

  func testApplicationIdentityComesFromCatalog() {
    XCTAssertEqual(
      ActionCatalog.target(forBundleIdentifier: "com.microsoft.teams2"),
      .microsoftTeams
    )
    XCTAssertEqual(
      ActionCatalog.target(forBundleIdentifier: "com.microsoft.teams"),
      .microsoftTeams
    )
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.openai.codex"), .codex)
    XCTAssertEqual(
      ActionCatalog.target(forBundleIdentifier: "com.anthropic.claudefordesktop"),
      .claude
    )
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.apple.Safari"), .safari)
    XCTAssertNil(ActionCatalog.target(forBundleIdentifier: "com.apple.TextEdit"))
  }

  func testMeetWebIdentityComesFromCatalog() throws {
    let meet = try XCTUnwrap(
      ActionCatalog.webApplication(in: .googleChrome, domain: .meeting)
    )

    XCTAssertEqual(meet.target, .googleMeet)
    XCTAssertEqual(meet.webApplication?.scheme, "https")
    XCTAssertEqual(meet.webApplication?.host, "meet.google.com")
    XCTAssertTrue(
      ActionCatalog.requiresWebApplicationDetection(
        bundleIdentifier: "com.google.Chrome",
        domain: .meeting
      )
    )
    XCTAssertFalse(
      ActionCatalog.requiresWebApplicationDetection(
        bundleIdentifier: "com.google.Chrome",
        domain: .browser
      )
    )
  }

  func testRejectsUnsupportedCatalogSchema() throws {
    let data = try XCTUnwrap(
      """
      {"schemaVersion":2,"actions":[],"applications":[],"mappings":[]}
      """.data(using: .utf8)
    )

    XCTAssertThrowsError(try BuiltInCatalog(data: data)) { error in
      XCTAssertEqual(error as? BuiltInCatalogError, .unsupportedSchemaVersion(2))
    }
  }

  func testRejectsIncompleteCatalog() throws {
    let data = try XCTUnwrap(
      """
      {"schemaVersion":1,"actions":[],"applications":[],"mappings":[]}
      """.data(using: .utf8)
    )

    XCTAssertThrowsError(try BuiltInCatalog(data: data)) { error in
      XCTAssertEqual(error as? BuiltInCatalogError, .incompleteActions)
    }
  }
}
