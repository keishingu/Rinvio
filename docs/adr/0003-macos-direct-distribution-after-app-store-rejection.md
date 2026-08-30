# ADR-0003: Mac App Store提出を終了し、Developer IDによる直接配布へ移行する

- Status: Accepted
- Date: 2026-08-20
- Scope: macOS distribution / App Review / Input Monitoring / Accessibility / product naming

## Context

QuickDraw Shortcuts 1.0 (build 2)をMac App Storeへ提出した。QuickDrawはForeground Applicationを判定し、ユーザーが設定したTriggerをActionへ変換して、対象Applicationの公式keyboard shortcutなど適切な実行経路へ配送する。

この中核体験は、次のmacOS権限を使用する。

- Input Monitoring: 設定済みTriggerを検出し、配送可能な場合だけ元の入力を消費する
- Accessibility: 対象Applicationへkeyboard shortcutを配送する

App Reviewは2026年8月20日、version 1.0 (2)を却下した。却下理由は次の4点だった。

1. Guideline 5.2.5 — Legal / Intellectual Property
   - App名とsubtitleに含まれる`QuickDraw`と`Mac`が、Appleの製品・サービスで使われる名称と混同を招く可能性がある。
2. Guideline 2.4.5(v) — Performance
   - Input Monitoringの要求はMac App Store Applicationに適切ではない。
3. Guideline 2.4.5 — Performance
   - Accessibility機能を、障害のあるユーザーを支援する目的以外で使用している。
4. Guideline 1.5 — Safety
   - GitHub IssuesへのURLだけでは、利用者に有用な情報を提供するsupport pageとして不十分である。

審査担当者名、Submission ID、連絡先などの個人情報と、審査メッセージの全文はこのRepositoryへ保存しない。

## Technical assessment

### Input MonitoringとAccessibilityは付加機能ではない

Input Monitoringを削除すると、QuickDrawはForeground Application以外にいる間のTriggerを安定して検出・消費できない。Accessibilityによるshortcut deliveryを削除すると、検出したActionを対象Applicationの公式shortcutへ配送できない。

権限説明の改善だけでは解決しない。今回の指摘は、入力を保存するか、利用統計を送信するかというprivacy disclosureではなく、権限の用途そのものに対する判断である。

### App Store向けの同等な代替経路は確認できていない

権限を使わず、任意のForeground Applicationに対して現在と同等のTrigger detection、conditional consumption、shortcut deliveryを提供できるMac App Store向けpublic APIは確認できていない。

Reference-onlyのAction Catalog、shortcut conflict検出、公式設定画面への案内などは権限なしでも提供できる。しかし、それらだけに限定すると「Applicationごとに異なるshortcutを共通Actionへ揃えて実行する」という製品の中核価値を失う。

### TestFlight、署名、notarizationとApp Reviewは別の判定である

TestFlightでの動作、code signing、notarizationの成功は、Mac App StoreのApp Reviewで権限の用途が認められることを保証しない。

Developer IDによる直接配布でもAppleのcode signingとnotarizationを使用できる。利用者はmacOSのSystem SettingsでInput MonitoringとAccessibilityを明示的に許可する必要があり、QuickDrawは未許可時に入力を消費しないfail-open behaviorを維持する。

## Decision

### 1. Mac App Storeへの現行Applicationの再提出を行わない

Input MonitoringまたはAccessibilityを隠す、外部helperを後からinstallする、審査時だけ機能を無効化するなど、App Reviewを迂回する実装は行わない。

Mac App Store向けにReference-onlyの別Applicationを提供する可能性は否定しない。ただし、単なる広告や直接配布版のinstallerではなく、単体で継続的なutilityを持つ別製品として、別のDecisionで検討する。

### 2. Developer ID署名とApple notarizationによる直接配布へ移行する

配布artifactはDeveloper ID Application certificateで署名し、Hardened Runtimeを有効にしてAppleのnotary serviceへ提出する。notarizationがAcceptedになったartifactだけを公開し、ticketをstapleしてGatekeeperで検証する。

初期配布形式は署名・notarization済みDMGを想定する。販売、license、update、download hostingの具体的な方式は別のDecisionで定める。

2026-08-30追記: 初期公開は需要と実機環境での挙動を確認するため、アカウント登録やLicense Keyのない無料配布とする。DMGはGitHub Releasesで公開し、LPから最新版へ直接リンクする。決済・licenseの検討は削除せず、将来の有料化を判断した時点で[Issue #13](https://github.com/keishingu/Rinvio/issues/13)を再開する。

### 3. 公開製品名から`QuickDraw`を外す

Appleの公開商標一覧には`QuickDraw®`がapplication programとして掲載されており、App Reviewでも具体的に指摘された。Mac App Store外の配布は商標利用の許諾を意味しないため、公開製品名、logo内の文字、website metadata、配布artifact名から`QuickDraw`を外す。

新しい製品名は商標、既存Application、domain、Repository名を確認したうえで別途決定する。RepositoryとGit historyに残る旧開発名は、公開brandとして利用しない。

### 4. 独立したsupport pageを用意する

GitHub Issuesを唯一のSupport URLにしない。公式websiteに少なくとも次を掲載する。

- 対応macOS versionとinstall手順
- Input MonitoringとAccessibilityが必要な理由、許可・解除手順
- Triggerが動作しない場合のtroubleshooting
- privacy policy
- 問い合わせ方法
- refund、license、updateに関する案内

GitHub Issuesを利用する場合も、support pageから選択可能な問い合わせ経路の一つとして扱う。

## Compatibility and safety requirements

直接配布への移行でも、既存の安全性と互換性要件を維持する。

- 保存済みCustom Trigger、Clear済みTrigger、Application Enablementを勝手に変更しない
- 権限がない、Targetが無効、対象Applicationでない、配送経路が利用できない場合は元のkey inputを通す
- Input MonitoringとAccessibilityを用途別に説明し、System Settingsからいつでも解除できるようにする
- key input、完全なURL、meeting情報、message内容、利用統計を保存・送信しない
- code signing、notarization、Gatekeeper検証に失敗したartifactを公開しない

公開製品名はRinvio、直接配布版のBundle IDは`com.keishingu.rinvio`とする。旧QuickDraw版からはCustom Trigger、Clear済みTrigger、Application Enablement、表示設定だけを一度移行し、読み込めない設定から危険なSystem-wide Triggerを有効化しない。

## Consequences

### Positive

- QuickDrawの中核であるglobal Trigger detectionとshortcut deliveryを維持できる。
- App Reviewを迂回する脆弱な実装を追加せずに済む。
- 価格、license policy、update cadenceを製品側で管理できる。
- Appleの署名、notarization、Gatekeeperによる配布時の安全確認を維持できる。

### Negative

- Mac App Store内の検索、商品page、rating、決済、automatic updateを利用できない。
- Website、決済、tax、license発行、download、update、supportを製品側で用意する必要がある。
- 利用者がDMGからApplicationをinstallし、必要なmacOS権限を自分で許可する必要がある。
- 製品名、Bundle ID、website、metadata、artifact名の変更が必要になる。

## Alternatives considered

### 権限の用途を再説明して再提出する

QuickDrawが一般的なkeyloggerではなく、設定済みTriggerだけを判定することはすでにReview Notesで説明した。今回の指摘はdata collectionではなく権限用途そのものに向けられているため、同じbinaryを説明だけ変えて再提出しても解決しないと判断した。

### Input MonitoringとAccessibilityを削除する

Mac App Storeへの掲載は可能になるかもしれないが、Trigger detectionとshortcut deliveryを失い、現在の製品目的を満たさないため採用しない。

### App Store版と直接配布版を同時に提供する

Reference-onlyのApp Store版が独立した価値を持つ可能性はある。一方、機能差、設定互換性、support、外部購入への誘導、二つのrelease channelを維持する必要がある。直接配布版への移行を優先し、現時点では採用しない。

### App Store向けhelperまたは後付けcomponentを配布する

App Reviewを迂回する設計になり、利用者の期待、security、maintenanceのいずれにも不利なため採用しない。

## Follow-up

- Rinvioの商標と既存製品の確認を継続する
- Developer ID release、notarization、DMG作成、verificationを実環境で確認する
- 決済とlicense方式を決定する
- 独立したsupport pageとprivacy pageを公開する
- 直接配布版のupdate方式を決定する
- Sandbox版から直接配布版への設定migrationを実機で確認する
- App Store固有のentitlement、metadata、release手順を整理する

## References

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple Trademark List](https://www.apple.com/legal/intellectual-property/trademark/appletmlist.html)
- [Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)
