import Foundation

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
  var f6Mute: String { text("F6 → ミュート", "F6 → Mute") }

  var actions: String { text("アクション", "Actions") }
  var applications: String { text("アプリケーション", "Applications") }
  var diagnostics: String { text("診断", "Diagnostics") }
  var noApplications: String { text("アプリケーションがありません", "No Applications") }
  var actionsSubtitle: String {
    text("1つの操作を、対応アプリごとの操作へ変換します。", "One action, translated for every supported application.")
  }
  var meetingControls: String { text("会議コントロール", "Meeting controls") }
  var muteToggle: String { text("ミュート切替", "Mute Toggle") }
  var muteDescription: String {
    text("現在の会議をミュート／ミュート解除します", "Mute or unmute the active meeting")
  }
  var applicationsSubtitle: String {
    text("各アプリでミュートがどう実行されるか確認できます。", "See how Mute is executed in each target.")
  }
  var detected: String { text("検出済み", "Detected") }
  var notInstalled: String { text("未インストール", "Not installed") }

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
  var f6Registered: String { text("F6 登録済み", "F6 registered") }
  var unavailable: String { text("利用不可", "Unavailable") }
  var recentRoutingLog: String { text("最近のルーティングログ", "Recent routing log") }
  var refresh: String { text("更新", "Refresh") }
  var copyDiagnostics: String { text("診断情報をコピー", "Copy Diagnostics") }

  var meetingControl: String { text("会議コントロール", "Meeting control") }
  var trigger: String { text("トリガー", "Trigger") }
  var triggerEditingDescription: String {
    text(
      "F6ルートの安定化後に、トリガー編集へ対応します。",
      "Trigger editing will follow after the fixed F6 route is hardened."
    )
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
  var muteMapping: String { text("ミュートのマッピング", "Mute mapping") }
  var capability: String { text("対応状況", "Capability") }
  var supported: String { text("対応済み", "Supported") }
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

  var menuTitle: String { text("QuickDraw PoC — F6でミュート", "QuickDraw PoC — F6 to Mute") }
  var openQuickDraw: String { text("QuickDrawを開く…", "Open QuickDraw…") }
  var dryRunMenu: String {
    text("ドライラン（F6でキーを送信しない）", "Dry Run (F6 does not send keys)")
  }
  var runDryCheckMenu: String {
    text("最後に使ったアプリでドライラン", "Run Dry Check on Last Active App")
  }
  var requestAccessibilityMenu: String {
    text("アクセシビリティを許可…", "Request Accessibility Permission…")
  }
  var hotKeyRegisteredMenu: String { text("ホットキー: F6 登録済み", "Hotkey: F6 Registered") }
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
    case .actions: actions
    case .applications: applications
    case .diagnostics: diagnostics
    }
  }

  func executionDetail(for application: ApplicationMapping) -> String {
    application.id == "googleMeet" ? activeTabAndShortcut : officialKeyboardShortcut
  }

  func localizedStatus(_ status: MuteStatus) -> MuteStatus {
    guard isJapanese else { return status }
    return MuteStatus(
      headline: localizedHeadline(status.headline),
      detail: localizedDetail(status.detail),
      target: status.target == "Not detected" ? "未検出" : status.target,
      isError: status.isError
    )
  }

  private func localizedHeadline(_ value: String) -> String {
    switch value {
    case "Starting…": "起動中…"
    case "Enabled — press F6": "有効 — F6を押してください"
    case "Disabled": "停止中"
    case "Dry Run enabled": "ドライランを有効化しました"
    case "Live delivery enabled": "実際のキー送信を有効化しました"
    case "Accessibility granted": "アクセシビリティは許可済みです"
    case "Accessibility permission requested": "アクセシビリティの許可を要求しました"
    case "Mute delivered": "ミュート操作を送信しました"
    case "Dry Run route matched": "ドライランで経路を確認しました"
    case "Mute not delivered": "ミュート操作を送信できませんでした"
    case "F6 registration failed": "F6を登録できませんでした"
    default: value
    }
  }

  private func localizedDetail(_ value: String) -> String {
    let exact: [String: String] = [
      "Preparing F6": "F6を準備しています",
      "Accessibility: Granted": "アクセシビリティ: 許可済み",
      "Accessibility: Required": "アクセシビリティ: 許可が必要",
      "Mute routing is paused": "ミュートのルーティングは停止中です",
      "F6 will route and log without sending a shortcut": "F6でショートカットを送らずに経路だけを記録します",
      "Return to Teams, Zoom, or Meet and press F6": "Teams、Zoom、Meetへ戻りF6を押してください",
      "Enable QuickDraw PoC in System Settings, then try again":
        "システム設定でQuickDraw PoCを有効にして、もう一度お試しください",
    ]
    if let localized = exact[value] { return localized }
    if value.hasPrefix("Would send ") {
      return value.replacingOccurrences(of: "Would send ", with: "送信予定: ")
    }
    return value
  }
}
