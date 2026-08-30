# QuickDraw Shortcuts — App Store提出情報

> [!IMPORTANT]
> この文書は、2026年8月20日のApp Reviewで却下されたMac App Store提出時点の履歴資料である。現在の配布方針ではなく、再提出用チェックリストとして使用しないこと。
>
> Input MonitoringとAccessibilityを使う現行の中核体験はMac App Storeの審査方針と両立しないと判断し、Developer ID署名とApple notarizationによる直接配布へ移行する。また、`QuickDraw`はAppleの商標として指摘されたため、公開製品名を変更する。判断の詳細は[ADR-0003](adr/0003-macos-direct-distribution-after-app-store-rejection.md)を参照すること。

この文書はApp Store Connectへ入力する公開情報と、App Reviewへ渡す検証手順の下書きである。実装上の製品名は`QuickDraw Shortcuts`、Bundle IDは`com.keishingu.quickdraw-shortcuts`とする。

## 基本情報

| 項目 | 値 |
|---|---|
| App名 | QuickDraw Shortcuts |
| Primary Category | Utilities |
| Secondary Category | Productivity |
| 基準ストアフロント | アメリカ合衆国 |
| 基準価格 | US$7.99 |
| 日本価格 | ¥800（手動指定） |
| Copyright | © 2026 Kei Shingu |
| Privacy Policy URL | https://github.com/keishingu/Rinvio/blob/main/docs/privacy-policy.md |
| Support URL | https://github.com/keishingu/Rinvio/issues |
| Marketing URL | https://github.com/keishingu/Rinvio |

有料配信にはAccount HolderによるPaid Apps Agreement、税務情報、入金口座の設定が必要。アメリカ合衆国を基準ストアフロントとしてUS$7.99を指定し、日本だけ¥800へ手動調整する。その他のストアフロントはUS$7.99を基準とするAppleの自動換算を使う。

## 日本語

### サブタイトル

アプリをまたいで操作を統一

### プロモーションテキスト

会議、チャット、メール、開発ツール、ブラウザ。アプリごとに違う頻出操作を、覚えやすい共通ショートカットへ揃えます。

### 説明

QuickDraw Shortcutsは、Macアプリごとに異なるキーボードショートカットを、Actionごとの共通Triggerへ揃えるユーティリティです。

たとえばミュートはOption＋M、カメラはOption＋C。QuickDrawはForegroundの対応アプリを判定し、Teams、Zoom、Google Meetそれぞれの公式ショートカットへ変換して配送します。

主な機能:

- Meeting、Chat、Mail、Development、Browserの頻出Actionを共通化
- Finderは明示的にONにした場合だけ、FinderがForegroundの間に動作
- macOSのワークスペース操作は現在値と推奨値を参照し、編集は純正のシステム設定へ委譲
- ActionごとのTriggerとアプリごとのMappingを確認・変更
- 修飾キー長押しで、現在のアプリに使えるShortcut Guideを表示
- アプリごとにQuickDrawの対象／対象外を設定
- 日本語／英語表示

QuickDrawは一般的なキーロガーではありません。設定済みTriggerだけを判定し、キー入力、完全なURL、会議情報、メッセージ内容、利用統計を保存・送信しません。Input MonitoringとAccessibilityは明示的に許可した場合だけ使用でき、QuickDrawを一時停止するか、対象アプリをOFFにするとTriggerを消費せず元の入力を通します。

第三者の製品名と商標は各所有者に帰属します。QuickDraw ShortcutsはApple、Microsoft、Google、Zoom、Slackその他の対応製品提供者による提携、承認、保証を受けた製品ではありません。

### キーワード

ショートカット,キーボード,効率化,会議,開発,ブラウザ,ユーティリティ,macOS

## English

### Subtitle

One shortcut language for Mac

### Promotional text

Use consistent shortcuts across meetings, chat, mail, development tools, browsers, and Finder—without memorizing every app's key map.

### Description

QuickDraw Shortcuts is a Mac utility that maps frequently used actions to consistent triggers across supported apps.

Mute with Option-M. Toggle the camera with Option-C. QuickDraw identifies the supported foreground app and delivers that app's official shortcut for Microsoft Teams, Zoom Workplace, or Google Meet.

Highlights:

- Consistent actions across Meeting, Chat, Mail, Development, and Browser apps
- Finder support that is off by default and active only while Finder is in the foreground
- Reference-only macOS workspace recommendations that open the official System Settings editor
- Editable action triggers and per-app shortcut mappings
- A modifier-hold Shortcut Guide for the current app
- Per-app enablement controls
- Japanese and English interface

QuickDraw is not a general-purpose keylogger. It matches configured triggers and does not store or transmit keystrokes, full URLs, meeting data, message content, or analytics. Input Monitoring and Accessibility work only after explicit permission. Pausing QuickDraw or disabling an app immediately releases its triggers.

Third-party product names and trademarks belong to their respective owners. QuickDraw Shortcuts is not affiliated with, endorsed by, or sponsored by Apple, Microsoft, Google, Zoom, Slack, or other supported product vendors.

### Keywords

shortcuts,keyboard,productivity,meeting,developer,browser,utility,macOS

## App Privacy回答案

- Data Collection: `No, we do not collect data from this app`
- Tracking: なし
- Third-party analytics / advertising SDK: なし
- Privacy manifest: `AppResources/PrivacyInfo.xcprivacy`
- Privacy policy本文: `docs/privacy-policy.md`

UserDefaultsはアプリ内設定の保存にだけ使用する。Application Supportにはschema version付きのTrigger、Mapping Override、Clear状態、Application Enablementを保存する。どちらも端末内に留まり、外部送信しない。

## 配布版への設定移行方針

Mac App Store版はSandbox Container内のApplication SupportとUserDefaultsへ保存する。未公開の開発用ビルドは別Bundle IDかつSandbox外であり、Store版から旧保存先を読むには追加のtemporary file exceptionが必要になるため、自動移行しない。初回公開時は新規インストールとして安全な既定値から開始し、FinderはOFF、macOSは参照専用を維持する。

公開後は`com.keishingu.quickdraw-shortcuts`、configuration schema、UserDefaults keyを維持し、Version updateで既存のCustom Trigger、Clear済みTrigger、Application Enablementを同じContainer内で移行する。migrationは入力schemaに対して冪等に実行する。将来、Developer ID版との移行が必要になった場合は、Sandbox例外ではなくユーザー操作による設定Export / Importを検討する。

## App Review Notes案

QuickDraw Shortcuts maps user-configured keyboard triggers to documented shortcuts in supported foreground applications.

1. Launch the app and open Information.
2. Grant Input Monitoring. This is used only to identify configured triggers; keystrokes are never recorded.
3. Grant Accessibility under Shortcut Delivery. This is used to post the documented destination shortcut.
4. In Applications, enable a supported installed target. Finder remains off by default.
5. For a third-party-free check, enable Finder, bring Finder to the foreground, select a folder, and use Parent Folder (`Option-Up`) or Open Selected Item (`Option-Down`). Disable Finder and verify the same triggers pass through immediately.
6. Bring another supported target to the foreground and use one of the triggers shown in the Action Catalog.
7. Pause QuickDraw or disable the target to verify that the original key input passes through immediately.

The macOS target is reference-only: QuickDraw reads the configured workspace shortcuts and opens System Settings for edits. It does not intercept or post system-wide workspace triggers.

Google Meet and Gmail routing can optionally inspect only the foreground Google Chrome tab URL. QuickDraw classifies `meet.google.com` or `mail.google.com`, does not retain the full URL, and does not read page content. All other Chrome hosts pass through to Browser actions or the original input.

No account, network service, analytics service, or reviewer credentials are required.

## App Sandbox temporary exception説明案

| 項目 | 内容 |
|---|---|
| Entitlement Key | `com.apple.security.temporary-exception.apple-events` |
| Value | `com.google.Chrome` |
| 必要性 | ForegroundのChrome TabがGoogle MeetまたはGmailかを、Chromeの公式Scripting Dictionary経由で判定するため |
| 有効になる機能 | Meeting / Mail / Browser Actionを正しいTargetへfail-closedでルーティングする |
| 審査方法 | Chromeで`meet.google.com`、`mail.google.com`、その他のhostをそれぞれForegroundにし、InformationのDry Runと直近のルーティング結果を確認する |
| データ最小化 | URLはhost分類にのみ使い、完全なURL、Tab title、meeting code、page contentを保存・送信しない |
| Feedback Assistant ID | `FB24304782` |

Appleはtemporary exceptionごとにApp Store Connectで必要性、評価方法、配列の各値、該当するFeedback IDの説明を求めている。Feedback Assistantへは2026年8月13日に「Temporary Apple Events exception for QuickDraw Shortcuts」として提出済み。

## スクリーンショット案

Mac用は16:10で`1280×800`、`1440×900`、`2560×1600`、`2880×1800`のいずれか。1〜10枚、透過なしで用意する。

1. Action Catalog — アプリをまたぐ共通Trigger
2. Meeting — Mute / Camera / Raise Handの対応表
3. Applications — アプリごとのON/OFFとForeground-onlyの説明
4. Shortcut Guide — 現在のアプリで使える操作
5. Privacy / Information — Input MonitoringとShortcut Deliveryを分けた説明
6. macOS — 現在値、推奨値、System Settingsへの編集導線

Version 1では静止画だけでAction／Target／Triggerの関係を説明できるため、App Previewは作成しない。利用状況が分かりにくい場合に後続Versionで再検討する。

## 人がApp Store Connectで行う項目

- Bundle ID `com.keishingu.quickdraw-shortcuts`をDeveloper Portalへ登録する
- XcodeへTeamを設定し、Mac App Distribution証明書とMac Installer Distribution証明書を用意する
- App Store ConnectでApp recordとSKUを作成する
- Paid Apps Agreement、税務情報、入金口座を完了する
- アメリカ合衆国を基準にUS$7.99、日本を手動で¥800に設定する
- App Store Connectのtemporary exception Usage Informationへ`FB24304782`を記載する
- 実署名ArchiveをUploadし、TestFlightのclean-account検証を行う
- スクリーンショット、連絡先、年齢区分、輸出コンプライアンス回答を確定する

## 公式資料

- [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)
- [App Sandbox information](https://developer.apple.com/help/app-store-connect/reference/app-uploads/app-sandbox-information)
- [App Sandbox Temporary Exception Entitlements](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html)
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Set a price](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price)
