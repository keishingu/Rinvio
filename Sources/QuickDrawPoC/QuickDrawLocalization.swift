import Foundation
import QuickDrawCore

enum AppLanguage: String, CaseIterable, Identifiable {
  case japanese = "ja"
  case english = "en"

  static let defaultsKey = "appLanguage"

  var id: Self { self }

  var displayName: String {
    switch self {
    case .japanese: "日本語"
    case .english: "English"
    }
  }

  static func preferred(defaults: UserDefaults = .standard) -> AppLanguage {
    if let stored = defaults.string(forKey: defaultsKey),
      let language = AppLanguage(rawValue: stored)
    {
      return language
    }
    return Locale.preferredLanguages.first?.hasPrefix("ja") == true ? .japanese : .english
  }
}

struct QuickDrawCopy {
  let language: AppLanguage

  private var isJapanese: Bool { language == .japanese }
  private func text(_ japanese: String, _ english: String) -> String {
    isJapanese ? japanese : english
  }

  var languageLabel: String { text("言語", "Language") }
  var chooseLanguage: String { text("表示言語を切り替える", "Change display language") }
  var enabled: String { text("有効", "Enabled") }
  var paused: String { text("停止中", "Paused") }
  var enableQuickDraw: String { text("QuickDrawを有効にする", "Enable QuickDraw") }
  var pauseQuickDraw: String { text("QuickDrawを一時停止する", "Pause QuickDraw") }
  var inspector: String { text("インスペクタ", "Inspector") }
  var showInspector: String { text("インスペクタを表示", "Show Inspector") }
  var hideInspector: String { text("インスペクタを隠す", "Hide Inspector") }
  var quickDrawEnabled: String { text("QuickDrawは有効です", "QuickDraw is enabled") }
  var quickDrawPaused: String { text("QuickDrawは停止中です", "QuickDraw is paused") }
  var actions: String { text("アクション", "Actions") }
  var applications: String { text("アプリケーション", "Applications") }
  var diagnostics: String { text("診断", "Diagnostics") }
  var noApplications: String { text("アプリケーションがありません", "No Applications") }
  var noActionsInCategory: String {
    text("このカテゴリにはActionがありません", "No Actions in this category")
  }
  var actionsSubtitle: String {
    text("1つの操作を、対応アプリごとの操作へ変換します。", "One action, translated for every supported application.")
  }
  var meetingControls: String { text("会議コントロール", "Meeting controls") }
  var panelsAndSharing: String { text("パネルと共有", "Panels and sharing") }
  var reactions: String { text("リアクション", "Reactions") }
  var agentSessions: String { text("エージェントセッション", "Agent sessions") }
  var terminals: String { text("ターミナル", "Terminal") }
  var commandsAndNavigation: String { text("コマンドと移動", "Commands and navigation") }
  var pageLoading: String { text("ページ読み込み", "Page loading") }
  var tabs: String { text("タブ", "Tabs") }
  var browserTools: String { text("ブラウザツール", "Browser tools") }
  var applicationsSubtitle: String {
    text(
      "各アプリでActionがどう実行されるか確認できます。",
      "See how each Action is executed in every target."
    )
  }
  var detected: String { text("検出済み", "Detected") }
  var notInstalled: String { text("未インストール", "Not installed") }
  func actionCount(_ count: Int) -> String {
    text("\(count)個のAction", "\(count) Actions")
  }
  func assignedTriggerCount(_ count: Int) -> String {
    text("\(count)個のTriggerを設定", "\(count) Triggers configured")
  }

  var diagnosticsSubtitle: String {
    text(
      "ルーティングに必要な情報だけを表示します。キー入力や会議URLは記録しません。",
      "Routing metadata only. QuickDraw does not record your keystrokes or meeting URLs."
    )
  }
  var currentStatus: String { text("現在の状態", "Current status") }
  var state: String { text("状態", "State") }
  var target: String { text("対象", "Target") }
  var result: String { text("結果", "Result") }
  var globalShortcut: String { text("グローバルショートカット", "Global shortcut") }
  func hotKeysRegistered(_ summary: String) -> String {
    text("\(summary) 登録済み", "\(summary) registered")
  }
  var unavailable: String { text("利用不可", "Unavailable") }
  var recentRoutingLog: String { text("最近のルーティングログ", "Recent routing log") }
  var refresh: String { text("更新", "Refresh") }
  var copyDiagnostics: String { text("診断情報をコピー", "Copy Diagnostics") }

  var meetingControl: String { text("会議コントロール", "Meeting control") }
  var trigger: String { text("トリガー", "Trigger") }
  var triggerEditingDescription: String {
    text(
      "Fキー、またはCommand・Control・Optionを含むショートカットを使用できます。",
      "Use a function key or a shortcut containing Command, Control, or Option."
    )
  }
  var changeShortcut: String { text("変更…", "Change…") }
  var pressShortcut: String { text("ショートカットを入力…", "Press shortcut…") }
  var unassigned: String { text("未割り当て", "Unassigned") }
  var noShortcut: String { text("ショートカットなし", "No shortcut") }
  var cancel: String { text("キャンセル", "Cancel") }
  var modified: String { text("変更済み", "Modified") }
  var defaultValue: String { text("デフォルト", "Default") }
  var restoreDefault: String { text("デフォルトに戻す", "Restore Default") }
  var restoreActionDefaults: String {
    text("このActionをすべてデフォルトに戻す…", "Restore All Defaults for This Action…")
  }
  var restoreActionTitle: String {
    text("このActionをデフォルトに戻しますか？", "Restore defaults for this Action?")
  }
  var restoreActionMessage: String {
    text(
      "Triggerとすべてのアプリ別Mappingがデフォルトに戻ります。",
      "The Trigger and every application mapping will return to their defaults."
    )
  }
  var shortcutCouldNotBeRead: String {
    text("そのキー入力はショートカットとして認識できません。", "That key input could not be recognized as a shortcut.")
  }
  var shortcutConflict: String { text("macOSショートカットと競合", "Conflicts with a macOS shortcut") }
  func triggerConflictDescription(_ conflicts: [TriggerConflict]) -> String {
    let names = conflicts.map(triggerConflictName).joined(separator: text("、", ", "))
    return text(
      "macOSの「\(names)」と競合します。対応アプリではQuickDrawが優先され、それ以外では元のショートカットが動作します。",
      "Conflicts with macOS “\(names)”. QuickDraw takes priority in a supported app; elsewhere, the original shortcut continues to work."
    )
  }

  private func triggerConflictName(_ conflict: TriggerConflict) -> String {
    switch conflict {
    case .configuredSystemShortcut:
      text("システム設定で有効なキーボードショートカット", "Keyboard shortcut enabled in System Settings")
    case .knownSystemShortcut(let shortcut):
      switch shortcut {
      case .copyStyle: text("スタイルをコピー", "Copy Style")
      case .showOrHideDock: text("Dockを表示／非表示", "Show or Hide the Dock")
      case .focusSearchField: text("検索フィールドへ移動", "Focus the Search Field")
      case .hideOtherApplications: text("ほかのアプリケーションを隠す", "Hide Other Applications")
      case .showInspector: text("インスペクタを表示", "Show Inspector")
      case .openDownloads: text("ダウンロードを開く", "Open Downloads")
      case .minimizeAllWindows: text("すべてのウインドウを最小化", "Minimize All Windows")
      case .showOrHideToolbar: text("ツールバーを表示／非表示", "Show or Hide the Toolbar")
      case .closeAllWindows: text("すべてのウインドウを閉じる", "Close All Windows")
      case .forceQuit: text("アプリケーションの強制終了", "Force Quit Applications")
      case .finderSearch: text("Finder検索", "Finder Search")
      case .toggleZoom: text("画面ズームを切り替える", "Toggle Screen Zoom")
      }
    }
  }
  var applicationMappings: String { text("アプリごとのマッピング", "Application mappings") }
  var execution: String { text("実行", "Execution") }
  var dryRun: String { text("ドライラン", "Dry Run") }
  var dryRunDescription: String {
    text(
      "ショートカットを送信せず、対象アプリと実行経路だけを確認します。",
      "Dry Run resolves the target without sending a shortcut."
    )
  }
  var testLastActiveApplication: String {
    text("最後に使ったアプリでテスト", "Test Last Active Application")
  }
  var identity: String { text("識別情報", "Identity") }
  var actionMappings: String { text("Actionのマッピング", "Action mappings") }
  var capability: String { text("対応状況", "Capability") }
  var supported: String { text("対応済み", "Supported") }
  func shortcutCapability(_ supported: Int, total: Int) -> String {
    text("\(supported)/\(total) Actionに対応", "\(supported) of \(total) Actions")
  }
  var method: String { text("実行方式", "Method") }
  var shortcut: String { text("ショートカット", "Shortcut") }
  var shortcutAccessibilityPrefix: String { text("ショートカット", "Shortcut") }

  var accessibility: String { text("アクセシビリティ", "Accessibility") }
  var permissionGranted: String { text("許可済み", "Permission granted") }
  var permissionRequired: String { text("許可が必要です", "Permission required") }
  var permissionDescription: String {
    text(
      "ルーティング後にアプリ固有のショートカットを送信するためだけに使用します。",
      "Required only to send the application shortcut after routing."
    )
  }
  var requestPermission: String { text("アクセスを許可…", "Request Permission…") }
  var checkAgain: String { text("もう一度確認", "Check Again") }

  var privacy: String { text("プライバシー", "Privacy") }
  var noKeyLogging: String { text("キー入力を記録しません", "No key logging") }
  var noFullURLStorage: String { text("完全なURLを保存しません", "No full URL storage") }
  var noTelemetry: String { text("テレメトリを送信しません", "No telemetry") }

  var officialKeyboardShortcut: String {
    text("公式キーボードショートカット", "Official keyboard shortcut")
  }
  var activeTabAndShortcut: String {
    text(
      "アクティブタブ判定＋公式ショートカット",
      "Active tab detection + official shortcut"
    )
  }

  var menuTitle: String {
    "QuickDraw PoC"
  }
  var openQuickDraw: String { text("QuickDrawを開く…", "Open QuickDraw…") }
  var dryRunMenu: String {
    text("ドライラン（キーを送信しない）", "Dry Run (does not send keys)")
  }
  var runDryCheckMenu: String {
    text(
      "最後に使ったアプリでミュートをドライラン",
      "Run Mute Dry Check on Last Active App"
    )
  }
  var requestAccessibilityMenu: String {
    text("アクセシビリティを許可…", "Request Accessibility Permission…")
  }
  func hotKeyRegisteredMenu(_ count: Int) -> String {
    text("ホットキー: \(count)個のTriggerを登録済み", "Hotkeys: \(count) Triggers Registered")
  }
  var privacyMenu: String {
    text(
      "プライバシー: Meet判定のみ・キー入力記録なし",
      "Privacy: Meet classification only; no key logging"
    )
  }
  var quitQuickDraw: String { text("QuickDraw PoCを終了", "Quit QuickDraw PoC") }
  var accessibilityGrantedMenu: String {
    text("アクセシビリティ: 許可済み", "Accessibility: Granted")
  }
  var accessibilityRequiredMenu: String {
    text("アクセシビリティ: 許可が必要", "Accessibility: Required")
  }
  var targetPrefix: String { text("対象", "Target") }

  func sectionTitle(_ section: QuickDrawSection) -> String {
    switch section {
    case .meeting: actionDomainName(.meeting)
    case .development: actionDomainName(.development)
    case .browser: actionDomainName(.browser)
    case .applications: applications
    case .diagnostics: diagnostics
    }
  }

  func actionDomainName(_ domain: ActionDomain) -> String {
    switch domain {
    case .meeting: text("Meeting", "Meeting")
    case .development: text("Development", "Development")
    case .browser: text("Browser", "Browser")
    }
  }

  func actionDomainSubtitle(_ domain: ActionDomain) -> String {
    switch domain {
    case .meeting:
      text(
        "会議アプリごとの操作差を、共通Actionへ変換します。",
        "Translate meeting controls into the same Actions across apps."
      )
    case .development:
      text(
        "開発ツールやエージェントを、共通の操作で扱います。",
        "Use the same Actions across development tools and agents."
      )
    case .browser:
      text(
        "ブラウザごとに異なるページ操作を統一します。",
        "Unify page controls that differ between browsers."
      )
    }
  }

  func executionDetail(for application: ApplicationMapping) -> String {
    application.id == "googleMeet" ? activeTabAndShortcut : officialKeyboardShortcut
  }

  func actionCategoryName(_ category: ActionCategory) -> String {
    switch category {
    case .meetingControls: meetingControls
    case .panelsAndSharing: panelsAndSharing
    case .reactions: reactions
    case .agentSessions: agentSessions
    case .terminals: terminals
    case .commandsAndNavigation: commandsAndNavigation
    case .pageLoading: pageLoading
    case .tabs: tabs
    case .browserTools: browserTools
    }
  }

  func actionName(_ action: Action) -> String {
    switch action {
    case .mute: text("ミュート切替", "Mute Toggle")
    case .camera: text("カメラ切替", "Camera Toggle")
    case .raiseHand: text("挙手切替", "Raise Hand Toggle")
    case .openChat: text("チャットを表示", "Show Chat")
    case .showParticipants: text("参加者を表示", "Show Participants")
    case .toggleCaptions: text("字幕切替", "Captions Toggle")
    case .shareScreen: text("画面共有", "Share Screen")
    case .switchCamera: text("カメラを切り替える", "Switch Camera")
    case .pictureInPicture: text("ピクチャ・イン・ピクチャ", "Picture in Picture")
    case .leaveMeeting: text("会議から退室", "Leave Meeting")
    case .reactionLike: text("リアクション：👍", "Reaction: 👍")
    case .reactionHeart: text("リアクション：❤️", "Reaction: ❤️")
    case .reactionClap: text("リアクション：👏", "Reaction: 👏")
    case .reactionLaugh: text("リアクション：😂", "Reaction: 😂")
    case .reactionWow: text("リアクション：😮", "Reaction: 😮")
    case .reactionCelebrate: text("リアクション：🎉", "Reaction: 🎉")
    case .newSession: text("新しいセッション", "New Session")
    case .toggleTerminal: text("ターミナル表示切替", "Toggle Terminal")
    case .newTerminal: text("新しいターミナル", "New Terminal")
    case .nextTerminal: text("次のターミナル", "Next Terminal")
    case .previousTerminal: text("前のターミナル", "Previous Terminal")
    case .splitTerminal: text("ターミナルを分割", "Split Terminal")
    case .focusSidebar: text("サイドバーにフォーカス", "Focus Sidebar")
    case .focusMainColumn: text("メインカラムにフォーカス", "Focus Main Column")
    case .focusTerminal: text("ターミナルにフォーカス", "Focus Terminal")
    case .commandPalette: text("コマンドパレット", "Command Palette")
    case .quickOpen: text("クイックオープン", "Quick Open")
    case .showKeyboardShortcuts: text("ショートカット一覧", "Keyboard Shortcuts")
    case .hardReload: text("スーパーリロード", "Hard Reload")
    case .nextTab: text("次のタブ", "Next Tab")
    case .previousTab: text("前のタブ", "Previous Tab")
    case .openDownloads: text("ダウンロードを表示", "Open Downloads")
    case .openDeveloperTools: text("開発者ツールを表示", "Open Developer Tools")
    case .reopenClosedTab: text("閉じたタブを開き直す", "Reopen Closed Tab")
    }
  }

  func actionDescription(_ action: Action) -> String {
    switch action {
    case .mute:
      text("現在の会議をミュート／ミュート解除します", "Mute or unmute the active meeting")
    case .camera:
      text("現在の会議でカメラをオン／オフします", "Turn the camera on or off in the active meeting")
    case .raiseHand:
      text("現在の会議で挙手／挙手解除します", "Raise or lower your hand in the active meeting")
    case .openChat:
      text("会議中のチャットパネルを表示／非表示にします", "Show or hide the in-meeting chat")
    case .showParticipants:
      text("会議の参加者パネルを表示／非表示にします", "Show or hide meeting participants")
    case .toggleCaptions:
      text("会議の字幕を表示／非表示にします", "Show or hide meeting captions")
    case .shareScreen:
      text("画面共有の開始または共有メニューを開きます", "Start sharing or open the sharing controls")
    case .switchCamera:
      text("利用するカメラを切り替えます", "Switch to the next available camera")
    case .pictureInPicture:
      text("会議をピクチャ・イン・ピクチャで表示します", "Open the meeting in picture-in-picture")
    case .leaveMeeting:
      text(
        "現在の会議でアプリ側の退室操作を実行します。確認の有無はアプリによって異なります",
        "Run the application's leave action for the active meeting. Confirmation behavior depends on the application"
      )
    case .reactionLike:
      text("👍リアクションを送信します", "Send a thumbs-up reaction")
    case .reactionHeart:
      text("❤️リアクションを送信します", "Send a heart reaction")
    case .reactionClap:
      text("👏リアクションを送信します", "Send a clapping reaction")
    case .reactionLaugh:
      text("😂リアクションを送信します", "Send a laughing reaction")
    case .reactionWow:
      text("😮リアクションを送信します", "Send a wow reaction")
    case .reactionCelebrate:
      text("🎉リアクションを送信します", "Send a celebration reaction")
    case .newSession:
      text(
        "現在の開発エージェントで新しいセッションを開始します",
        "Start a new session in the active development agent"
      )
    case .toggleTerminal:
      text(
        "現在の開発ツールで統合ターミナルの表示を切り替えます",
        "Toggle the integrated terminal in the active development tool"
      )
    case .newTerminal:
      text(
        "現在の開発ツールで新しい統合ターミナルを作成します",
        "Create a new integrated terminal in the active development tool"
      )
    case .nextTerminal:
      text(
        "次のターミナルセッションへ移動します",
        "Move to the next terminal session"
      )
    case .previousTerminal:
      text(
        "前のターミナルセッションへ移動します",
        "Move to the previous terminal session"
      )
    case .splitTerminal:
      text(
        "現在のターミナルを標準の方向に分割します",
        "Split the current terminal in the application's default direction"
      )
    case .focusSidebar:
      text(
        "開発アプリのサイドバーへキーボードフォーカスを移します",
        "Move keyboard focus to the development application's sidebar"
      )
    case .focusMainColumn:
      text(
        "開発アプリのメインカラムへキーボードフォーカスを移します",
        "Move keyboard focus to the development application's main column"
      )
    case .focusTerminal:
      text(
        "開発アプリのターミナルへキーボードフォーカスを移します",
        "Move keyboard focus to the development application's terminal"
      )
    case .commandPalette:
      text(
        "現在の開発ツールでコマンドパレットを開きます",
        "Open the command palette in the active development tool"
      )
    case .quickOpen:
      text(
        "ファイル名からファイルを検索して開きます",
        "Find and open a file by name"
      )
    case .showKeyboardShortcuts:
      text(
        "現在の開発ツールのショートカット一覧を開きます",
        "Open the keyboard shortcut reference for the active development tool"
      )
    case .hardReload:
      text(
        "キャッシュを無視して現在のページを再読み込みします",
        "Reload the current page while bypassing cached content"
      )
    case .nextTab:
      text("ブラウザの次のタブへ移動します", "Move to the next browser tab")
    case .previousTab:
      text("ブラウザの前のタブへ移動します", "Move to the previous browser tab")
    case .openDownloads:
      text("ブラウザのダウンロード一覧を開きます", "Open the browser downloads list")
    case .openDeveloperTools:
      text(
        "現在のページの開発者ツールを開きます",
        "Open developer tools for the current page"
      )
    case .reopenClosedTab:
      text("最後に閉じたタブを開き直します", "Reopen the most recently closed tab")
    }
  }

  func mappingTitle(_ action: Action) -> String {
    text("\(actionName(action))のマッピング", "\(actionName(action)) mapping")
  }

  func localizedShortcutError(_ value: String) -> String {
    guard isJapanese else { return value }
    if value == "Use a function key or a shortcut containing Command, Control, or Option" {
      return "Fキー、またはCommand・Control・Optionを含むショートカットを使用してください。"
    }
    if value.hasPrefix("This trigger is already assigned to ") {
      let englishName = String(value.dropFirst("This trigger is already assigned to ".count))
      let localizedName =
        Action.allCases.first { $0.displayName == englishName }
        .map(actionName) ?? englishName
      return "このTriggerはすでに\(localizedName)へ割り当てられています。"
    }
    if value.contains("could not be registered") {
      return "このショートカットはmacOSへ登録できませんでした。別の組み合わせを選んでください。"
    }
    return value
  }

  func localizedStatus(_ status: ActionStatus) -> ActionStatus {
    guard isJapanese else { return status }
    return ActionStatus(
      action: status.action,
      headline: localizedHeadline(status.headline),
      detail: localizedDetail(status.detail, action: status.action),
      target: status.target == "Not detected" ? "未検出" : status.target,
      isError: status.isError
    )
  }

  private func localizedHeadline(_ value: String) -> String {
    for action in Action.allCases {
      if value == "\(action.displayName) delivered" {
        return "\(actionName(action))を送信しました"
      }
      if value == "\(action.displayName) not delivered" {
        return "\(actionName(action))を送信できませんでした"
      }
    }
    return switch value {
    case "Starting…": "起動中…"
    case "Enabled — shortcuts ready": "有効 — ショートカットを使用できます"
    case "Disabled": "停止中"
    case "Dry Run enabled": "ドライランを有効化しました"
    case "Live delivery enabled": "実際のキー送信を有効化しました"
    case "Accessibility granted": "アクセシビリティは許可済みです"
    case "Accessibility permission requested": "アクセシビリティの許可を要求しました"
    case "Dry Run route matched": "ドライランで経路を確認しました"
    case "Global shortcut registration failed": "グローバルショートカットを登録できませんでした"
    default: value
    }
  }

  private func localizedDetail(_ value: String, action: Action?) -> String {
    let exact: [String: String] = [
      "Preparing shortcuts": "ショートカットを準備しています",
      "Accessibility: Granted": "アクセシビリティ: 許可済み",
      "Accessibility: Required": "アクセシビリティ: 許可が必要",
      "Action routing is paused": "Actionのルーティングは停止中です",
      "Configured triggers will route and log without sending a shortcut":
        "設定したTriggerでショートカットを送らずに経路だけを記録します",
      "Return to a supported application and use a configured trigger":
        "対応アプリへ戻り設定したTriggerを使用してください",
      "Enable QuickDraw PoC in System Settings, then try again":
        "システム設定でQuickDraw PoCを有効にして、もう一度お試しください",
    ]
    if let localized = exact[value] { return localized }
    if let action, value.contains(" has no shortcut for ") {
      let suffix =
        value.split(separator: "·", maxSplits: 1).dropFirst().first
        .map { " ·\($0)" } ?? ""
      let target =
        value
        .replacingOccurrences(of: "\(action.displayName) has no shortcut for ", with: "")
        .split(separator: "·", maxSplits: 1).first.map(String.init) ?? "対象アプリ"
      return "\(target)では\(actionName(action))のショートカットがありません\(suffix)"
    }
    if value.contains(" would send ") {
      for action in Action.allCases {
        let prefix = "\(action.displayName) would send "
        if value.hasPrefix(prefix) {
          return value.replacingOccurrences(of: prefix, with: "\(actionName(action))送信予定: ")
        }
      }
    }
    return value
  }
}
