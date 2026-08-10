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
    XCTAssertEqual(
      ActionCatalog.target(forBundleIdentifier: "com.microsoft.VSCode"),
      .visualStudioCode
    )
    XCTAssertEqual(
      ActionCatalog.target(forBundleIdentifier: "com.todesktop.230313mzl4w4u92"),
      .cursor
    )
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.apple.dt.Xcode"), .xcode)
    XCTAssertEqual(
      ActionCatalog.target(forBundleIdentifier: "com.jetbrains.intellij"),
      .intellijIdea
    )
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.jetbrains.WebStorm"), .webStorm)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.jetbrains.RubyMine"), .rubyMine)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.jetbrains.pycharm"), .pyCharm)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.jetbrains.goland"), .goLand)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.jetbrains.CLion"), .cLion)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.jetbrains.rider"), .rider)
    XCTAssertEqual(
      ActionCatalog.target(forBundleIdentifier: "com.google.android.studio"),
      .androidStudio
    )
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.apple.Terminal"), .terminal)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.googlecode.iterm2"), .iTerm2)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.mitchellh.ghostty"), .ghostty)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.apple.Safari"), .safari)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "org.mozilla.firefox"), .firefox)
    XCTAssertEqual(
      ActionCatalog.target(forBundleIdentifier: "com.microsoft.edgemac"),
      .microsoftEdge
    )
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.brave.Browser"), .brave)
    XCTAssertEqual(
      ActionCatalog.target(forBundleIdentifier: "company.thebrowser.Browser"),
      .arc
    )
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.tinyspeck.slackmacgap"), .slack)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.hnc.Discord"), .discord)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.oss-cairn.desktop"), .cairn)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.oss-cairn.desktop.dev"), .cairn)
    XCTAssertNil(ActionCatalog.target(forBundleIdentifier: "jp.naver.line.mac"))
    XCTAssertNil(ActionCatalog.target(forBundleIdentifier: "com.apple.TextEdit"))
  }

  func testEveryApplicationHasAnOfficialURL() {
    for target in ActionTarget.allCases {
      XCTAssertEqual(
        ActionCatalog.application(for: target).officialURL?.scheme,
        "https",
        "\(target.rawValue) must link to an official HTTPS page"
      )
    }
  }

  func testTeamsParticipatesInMeetingAndChatDomains() {
    XCTAssertEqual(
      Set(ActionCatalog.application(for: .microsoftTeams).domains),
      Set([.meeting, .chat])
    )
  }

  func testJetBrainsApplicationsShareDefaultMappingsButKeepTheirOwnIdentity() {
    let intellijShortcut = ActionCatalog.defaultShortcut(
      for: .goToDefinition,
      target: .intellijIdea
    )

    for target in [
      ActionTarget.webStorm, .rubyMine, .pyCharm, .goLand, .cLion, .rider, .androidStudio,
    ] {
      XCTAssertEqual(
        ActionCatalog.defaultShortcut(for: .goToDefinition, target: target), intellijShortcut)
      XCTAssertNotEqual(target, .intellijIdea)
    }
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
      {"schemaVersion":3,"actions":[],"applications":[],"mappings":[]}
      """.data(using: .utf8)
    )

    XCTAssertThrowsError(try BuiltInCatalog(data: data)) { error in
      XCTAssertEqual(error as? BuiltInCatalogError, .unsupportedSchemaVersion(3))
    }
  }

  func testRejectsIncompleteCatalog() throws {
    let data = try XCTUnwrap(
      """
      {"schemaVersion":2,"actions":[],"applications":[],"mappings":[]}
      """.data(using: .utf8)
    )

    XCTAssertThrowsError(try BuiltInCatalog(data: data)) { error in
      XCTAssertEqual(error as? BuiltInCatalogError, .incompleteActions)
    }
  }
}
