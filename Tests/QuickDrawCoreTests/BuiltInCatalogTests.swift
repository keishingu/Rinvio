import Foundation
import QuickDrawCore
import XCTest

final class BuiltInCatalogTests: XCTestCase {
  func testBundledCatalogDefinesEveryActionAndApplication() throws {
    for action in Action.allCases {
      XCTAssertNotNil(ActionCatalog.defaultTrigger(for: action))
      if !ActionCatalog.isSystemWide(action) {
        XCTAssertTrue(
          ActionTarget.allCases.contains {
            ActionCatalog.defaultShortcut(for: action, target: $0) != nil
          }
        )
      }
    }

    for target in ActionTarget.allCases {
      XCTAssertEqual(ActionCatalog.application(for: target).target, target)
    }
  }

  func testApplicationIdentityComesFromCatalog() {
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.apple.finder"), .finder)
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
      ActionCatalog.target(forBundleIdentifier: "com.google.antigravity"),
      .antigravity
    )
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "com.apple.Notes"), .appleNotes)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "notion.id"), .notion)
    XCTAssertEqual(ActionCatalog.target(forBundleIdentifier: "md.obsidian"), .obsidian)
    XCTAssertEqual(
      ActionCatalog.target(forBundleIdentifier: "com.microsoft.onenote.mac"),
      .microsoftOneNote
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

  func testSystemActionsAreNativeSettingsAndFinderMappingsRemainOptIn() {
    XCTAssertTrue(ActionCatalog.isSystemWide(.missionControl))
    XCTAssertTrue(ActionCatalog.isSystemWide(.nextDesktop))
    XCTAssertFalse(ActionCatalog.isSystemWide(.finderParentFolder))
    XCTAssertEqual(ActionCatalog.application(for: .macOS).bundleIdentifiers, [])
    for action in Action.allCases where ActionCatalog.isSystemWide(action) {
      XCTAssertNil(ActionCatalog.defaultShortcut(for: action, target: .macOS))
    }
    let expectedSystemTriggers: [Action: String] = [
      .missionControl: "⇧⌘↑",
      .applicationExpose: "⇧⌘↓",
      .previousDesktop: "⇧⌘←",
      .nextDesktop: "⇧⌘→",
      .showDesktop: "F11",
      .showNotificationCenter: "⌃⌘N",
      .toggleDoNotDisturb: "⌃⌘D",
      .toggleStageManager: "⌃⌘S",
      .fillWindow: "⌃⌘↑",
      .tileWindowLeft: "⌃⌘←",
      .tileWindowRight: "⌃⌘→",
      .switchDesktop1: "⌘1",
      .switchDesktop2: "⌘2",
      .switchDesktop3: "⌘3",
      .switchDesktop4: "⌘4",
      .switchDesktop5: "⌘5",
    ]
    for (action, trigger) in expectedSystemTriggers {
      XCTAssertEqual(ActionCatalog.defaultTrigger(for: action)?.displayValue, trigger)
    }
    XCTAssertEqual(ActionCatalog.application(for: .finder).bundleIdentifiers, ["com.apple.finder"])
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .finderParentFolder, target: .finder)?.displayValue,
      "⌘↑"
    )
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .finderDownloads, target: .finder)?.displayValue,
      "⌘⌥L"
    )
    XCTAssertEqual(ActionCatalog.defaultTrigger(for: .finderCopyPath)?.displayValue, "⌘L")
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .finderCopyPath, target: .finder)?.displayValue,
      "⌥⌘C"
    )
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

  func testGmailWebIdentityComesFromCatalog() throws {
    let gmail = try XCTUnwrap(
      ActionCatalog.webApplication(in: .googleChrome, domain: .mail)
    )

    XCTAssertEqual(gmail.target, .gmail)
    XCTAssertEqual(gmail.webApplication?.scheme, "https")
    XCTAssertEqual(gmail.webApplication?.host, "mail.google.com")
    XCTAssertTrue(
      ActionCatalog.requiresWebApplicationDetection(
        bundleIdentifier: "com.google.Chrome",
        domain: .mail
      )
    )
  }

  func testWebApplicationMatchesActiveBrowserURL() throws {
    XCTAssertEqual(
      ActionCatalog.webApplication(
        in: .googleChrome,
        matching: try XCTUnwrap(URL(string: "https://meet.google.com/abc-defg-hij"))
      )?.target,
      .googleMeet
    )
    XCTAssertEqual(
      ActionCatalog.webApplication(
        in: .googleChrome,
        matching: try XCTUnwrap(URL(string: "https://mail.google.com/mail/u/0/#inbox"))
      )?.target,
      .gmail
    )
    XCTAssertEqual(
      ActionCatalog.webApplication(
        in: .googleChrome,
        matching: try XCTUnwrap(URL(string: "https://teams.cloud.microsoft/v2/"))
      )?.target,
      .microsoftTeamsWeb
    )
    XCTAssertEqual(
      ActionCatalog.webApplication(
        in: .googleChrome,
        matching: try XCTUnwrap(URL(string: "https://teams.microsoft.com/v2/"))
      )?.target,
      .microsoftTeamsWeb
    )
    XCTAssertEqual(
      ActionCatalog.webApplication(
        in: .googleChrome,
        matching: try XCTUnwrap(URL(string: "https://app.zoom.us/wc/123/join"))
      )?.target,
      .zoomWeb
    )
    XCTAssertEqual(
      ActionCatalog.webApplication(
        in: .googleChrome,
        matching: try XCTUnwrap(URL(string: "https://www.notion.so/workspace/page"))
      )?.target,
      .notionWeb
    )
    XCTAssertNil(
      ActionCatalog.webApplication(
        in: .googleChrome,
        matching: try XCTUnwrap(URL(string: "https://example.com"))
      )
    )
  }

  func testTeamsWebInheritsMeetingMappings() {
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .mute, target: .microsoftTeamsWeb),
      ActionCatalog.defaultShortcut(for: .mute, target: .microsoftTeams)
    )
    XCTAssertEqual(ActionCatalog.application(for: .microsoftTeamsWeb).domains, [.meeting])
  }

  func testNoteMappingsComeFromCatalog() {
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .openNote, target: .notionWeb)?.displayValue,
      "⌘P"
    )
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .newNote, target: .obsidian)?.displayValue,
      "⌘N"
    )
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .newNote, target: .notion)?.displayValue,
      "⌘N"
    )
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .openNote, target: .notion),
      ActionCatalog.defaultShortcut(for: .openNote, target: .notionWeb)
    )
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .addComment, target: .obsidian)?.displayValue,
      "⌘/"
    )
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .openNote, target: .appleNotes)?.displayValue,
      "⌥⌘F"
    )
    XCTAssertEqual(
      ActionCatalog.defaultShortcut(for: .nextNote, target: .microsoftOneNote)?.displayValue,
      "⌘Page Down"
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
