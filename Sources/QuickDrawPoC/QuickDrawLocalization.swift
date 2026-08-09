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
  var actionsSubtitle: String {
    text("1つの操作を、対応アプリごとの操作へ変換します。", "One action, translated for every supported application.")
  }
  var meetingControls: String { text("会議コントロール", "Meeting controls") }
  var applicationsSubtitle: String {
    text(
      "各アプリでActionがどう実行されるか確認できます。",
      "See how each Action is executed in every target."
    )
  }
  var detected: String { text("検出済み", "Detected") }
  var notInstalled: String { text("未インストール", "Not installed") }
  var threeActions: String { text("3つのAction", "3 Actions") }

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
  func hotKeyRegisteredMenu(_ summary: String) -> String {
    text("ホットキー: \(summary) 登録済み", "Hotkeys: \(summary) Registered")
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
    case .actions: actions
    case .applications: applications
    case .diagnostics: diagnostics
    }
  }

  func executionDetail(for application: ApplicationMapping) -> String {
    application.id == "googleMeet" ? activeTabAndShortcut : officialKeyboardShortcut
  }

  func actionName(_ action: MeetingAction) -> String {
    switch action {
    case .mute: text("ミュート切替", "Mute Toggle")
    case .camera: text("カメラ切替", "Camera Toggle")
    case .raiseHand: text("挙手切替", "Raise Hand Toggle")
    }
  }

  func actionDescription(_ action: MeetingAction) -> String {
    switch action {
    case .mute:
      text("現在の会議をミュート／ミュート解除します", "Mute or unmute the active meeting")
    case .camera:
      text("現在の会議でカメラをオン／オフします", "Turn the camera on or off in the active meeting")
    case .raiseHand:
      text("現在の会議で挙手／挙手解除します", "Raise or lower your hand in the active meeting")
    }
  }

  func mappingTitle(_ action: MeetingAction) -> String {
    text("\(actionName(action))のマッピング", "\(actionName(action)) mapping")
  }

  func localizedShortcutError(_ value: String) -> String {
    guard isJapanese else { return value }
    if value == "Use a function key or a shortcut containing Command, Control, or Option" {
      return "Fキー、またはCommand・Control・Optionを含むショートカットを使用してください。"
    }
    if value.hasPrefix("This trigger is already assigned to ") {
      let englishName = String(value.dropFirst("This trigger is already assigned to ".count))
      let localizedName: String
      switch englishName {
      case MeetingAction.mute.displayName: localizedName = actionName(.mute)
      case MeetingAction.camera.displayName: localizedName = actionName(.camera)
      case MeetingAction.raiseHand.displayName: localizedName = actionName(.raiseHand)
      default: localizedName = englishName
      }
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
      detail: localizedDetail(status.detail),
      target: status.target == "Not detected" ? "未検出" : status.target,
      isError: status.isError
    )
  }

  private func localizedHeadline(_ value: String) -> String {
    switch value {
    case "Starting…": "起動中…"
    case "Enabled — shortcuts ready": "有効 — ショートカットを使用できます"
    case "Disabled": "停止中"
    case "Dry Run enabled": "ドライランを有効化しました"
    case "Live delivery enabled": "実際のキー送信を有効化しました"
    case "Accessibility granted": "アクセシビリティは許可済みです"
    case "Accessibility permission requested": "アクセシビリティの許可を要求しました"
    case "Dry Run route matched": "ドライランで経路を確認しました"
    case "Mute delivered": "ミュート操作を送信しました"
    case "Camera delivered": "カメラ操作を送信しました"
    case "Raise Hand delivered": "挙手操作を送信しました"
    case "Mute not delivered": "ミュート操作を送信できませんでした"
    case "Camera not delivered": "カメラ操作を送信できませんでした"
    case "Raise Hand not delivered": "挙手操作を送信できませんでした"
    case "Global shortcut registration failed": "グローバルショートカットを登録できませんでした"
    default: value
    }
  }

  private func localizedDetail(_ value: String) -> String {
    let exact: [String: String] = [
      "Preparing shortcuts": "ショートカットを準備しています",
      "Accessibility: Granted": "アクセシビリティ: 許可済み",
      "Accessibility: Required": "アクセシビリティ: 許可が必要",
      "Action routing is paused": "Actionのルーティングは停止中です",
      "Configured triggers will route and log without sending a shortcut":
        "設定したTriggerでショートカットを送らずに経路だけを記録します",
      "Return to Teams, Zoom, or Meet and use a configured trigger":
        "Teams、Zoom、Meetへ戻り設定したTriggerを使用してください",
      "Enable QuickDraw PoC in System Settings, then try again":
        "システム設定でQuickDraw PoCを有効にして、もう一度お試しください",
    ]
    if let localized = exact[value] { return localized }
    if value.contains(" would send ") {
      return
        value
        .replacingOccurrences(of: "Mute would send ", with: "ミュート送信予定: ")
        .replacingOccurrences(of: "Camera would send ", with: "カメラ送信予定: ")
        .replacingOccurrences(of: "Raise Hand would send ", with: "挙手送信予定: ")
    }
    return value
  }
}
