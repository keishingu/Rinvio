# QuickDraw ショートカット設計原則と System Settings / Finder opt-in 設計

- ステータス: Phase 1 / macOS純正設定連携・Finder opt-in 実装済み
- 更新日: 2026-08-12
- 対象: QuickDrawが提供するSuggested Trigger、macOS純正設定連携、Finder Target

> この文書を正本として、Phase 1のSuggested Trigger、macOS純正設定の参照・編集導線、Finder opt-inを実装した。Target-aware Trigger、Browser Adapter、未確定のFinder Actionは引き続き将来設計である。

## 1. 背景

macOSの修飾キーには、歴史的に複数の体系が同居している。特にOptionは「alternative」と説明されることが多いが、何に対する代替なのかが操作やアプリによって異なり、QuickDrawのTriggerを一貫して配置する基準にはしにくい。

QuickDrawでは、Optionを「アプリ内のあらゆるメニュー操作」へ広げない。Optionは、QuickDrawがアプリを横断して呼び出す**アプリレベルの意味操作**に使う。既存アプリ内のCopy Style、Paste Style、Inspector、ToolbarなどをQuickDraw流に再配置する意図はない。

この原則は、既存世界をすべて再配線する憲法ではない。QuickDrawが新しく提供するTriggerを、意味に沿って迷わず配置するための設計原則である。すでに広く定着したショートカットは、原則より既存文化を優先できる。

## 2. 修正版の境界

| レイヤー | 対象 | 例 |
|---|---|---|
| `Control` | テキスト、CUI、カーソル、エディタ操作 | 行移動、コメント、Format、Rename |
| `Command` | 定着したOS / GUI共通操作 | Copy、Reload、Close、Quit |
| `Command + Control` | Command領域のうち範囲が小さいSystem UI／現在のウインドウ操作 | 通知センター、おやすみモード、ウインドウ配置 |
| `Option` | QuickDrawが統一するネイティブアプリ操作 | Mute、New Session、Finder操作 |
| `Command + Option` | Webアプリ、ネストされたアプリ／サブシステム | 将来のGoogle Meet、Web版Zoom、DevTools |
| `Shift` | 逆方向、範囲、反転、強制版 | Previous、選択範囲、Redo、Hard Reload、Close All |

### 適用ルール

1. Actionの意味がテキスト編集、CUI、カーソル、エディタ操作ならControl領域に置く。
2. Copy、Reload、Close、Quitのように定着したGUI共通操作はCommand文化を尊重する。
3. Command領域のうち、小さなSystem UIや現在のウインドウだけへ作用するActionはCommand + Control領域に置く。
4. QuickDrawが複数のネイティブアプリ間で意味を統一するActionはOption領域に置く。
5. Webアプリやアプリ内サブシステムのActionはCommand + Option領域を候補とする。
6. Shiftは「逆方向」だけでなく、範囲、反転、Rubyの `!` に相当する強制版を表す。
7. FinderはOSそのものではなく、ネイティブアプリとしてOption領域に置く。
8. 既存アプリの内部メニューを網羅的に再配置しない。QuickDrawが扱わない既存ショートカットは、競合検出の予約情報として認識する。

## 3. Meeting

### Phase 1

Phase 1ではネイティブ／Webを区別せず、すべてOptionへ寄せる。これは現在のAction単位Triggerモデルで、一貫したmuscle memoryを先に成立させるための暫定ルールである。

| Action | Before | Phase 1 |
|---|---:|---:|
| Mute | `⌘⌥M` | `⌥M` |
| Camera | `⌘⌥C` | `⌥C` |
| Raise Hand | `⌘⌥H` | `⌥H` |
| Open Chat | `⌘⌥O` | `⌥O` |
| Participants | `⌘⌥P` | `⌥P` |
| Captions | `⌘⌥L` | `⌥L` |
| Share Screen | `⌘⌥S` | `⌥S` |
| Switch Camera | `⌘⌥X` | `⌥X` |
| Picture in Picture | `⌘⌥I` | `⌥I` |
| Leave Meeting | `⌘⌥G` | `⌥G` |
| Reactions | `⌘⌥1〜6` | `⌥1〜6` |

Leave Meetingのような破壊的Actionは、キー体系とは別に確認、長押し、明示的opt-inなどの安全策を必要とする。

### Phase 2: Target-aware Trigger

Phase 2では、同じActionでも実行Targetの種類に応じてTriggerを変える。

| Target | Mute候補 |
|---|---:|
| Zoomネイティブ | `⌥M` |
| Teamsネイティブ | `⌥M` |
| Google Meet | `⌘⌥M` |
| Zoom Web | `⌘⌥M` |

現在の「ActionにつきTriggerは1つ」というモデルでは表現できない。Target-aware TriggerはBrowser Adapterと一緒に設計し、Phase 1の必須条件にはしない。

## 4. Development

Developmentを一括してOptionへ移さず、操作の性質で分ける。

### アプリ／UI操作

| Action例 | Before | After候補 |
|---|---:|---:|
| New Session | `⌘⌥N` | `⌥N` |
| Toggle Terminal | `⌘⌥T` | `⌥T` |
| Command Palette | `⌘⌥K` | `⌥K` |
| Quick Open | `⌘⌥Q` | `⌥O` |
| Focus Sidebar | `⌘⌥F1` | `⌥F1` |
| Focus Main Column | `⌘⌥F2` | `⌥F2` |
| Focus Terminal | `⌘⌥F3` | `⌥F3` |

### テキスト／エディタ操作

ここはControl系を維持する。

| Action | Before | 方針 |
|---|---:|---|
| Go to Symbol | `⌃⌥O` | 維持候補 |
| Format Document | `⌃⌥F` | 維持候補 |
| Rename Symbol | `⌃⌥R` | 維持候補 |
| Find References | `⌃⌥U` | 維持候補 |
| Quick Fix | `⌃⌥.` | 維持候補 |
| Toggle Line Comment | `⌃⌥/` | 維持候補 |
| Move Line Up／Down | `⌃⌥↑/↓` | 維持候補 |
| Run Project | `⌃⌥G` | 個別判断 |
| Next／Previous Issue | `⌃⌥] / [` | Shift規則を含め再検討 |

`⌃⌥`は「Control領域の操作だが、アプリ固有のエディタ機能」という合成として説明できる。`⌃A/E/F/B/N/P`など既存のテキスト移動は一切変更しない。

## 5. Browser

Browserは既存のCommand文化を尊重して個別判断する。

| Action | Before | After候補 | 理由 |
|---|---:|---:|---|
| Hard Reload | `⌘⌥R` | `⇧⌘R` | Reloadの強制版 |
| Next Tab | `⌘⌥]` | `⌥]` | ブラウザ固有の移動 |
| Previous Tab | `⌘⌥[` | `⇧⌥]` | Nextの逆 |
| Downloads | `⌘⌥D` | `⌥D` | ブラウザ固有画面 |
| Developer Tools | `⌘⌥E` | `⌘⌥I` | ブラウザ内サブシステム |
| Reopen Closed Tab | `⌘⌥Z` | `⇧⌘T` | 定着済みの共通ブラウザ操作 |

`⌘R`、`⌘W`、`⌘Q`、`⌘T`のように意味が定着しているものは、QuickDrawの原則より既存文化を優先する。

## 6. Mail

メールの新規作成と検索は多くのmacOS Applicationで定着したCommand文化を維持する。`Shift`は検索範囲を広げる意味として扱い、返信・整理などメール固有のActionはOption領域へ置く。

| Action | Suggested Trigger | 意味 |
|---|---|---|
| New Message | `⌘N` | Application共通の新規作成 |
| Find in Message | `⌘F` | 現在のメール内検索 |
| Search All Mail | `⇧⌘F` | 全メール／広域検索 |
| Reply | `⌥R` | メール固有の返信 |
| Reply All | `⇧⌥R` | Replyの範囲大 |
| Forward | `⌥F` | メール固有の転送 |
| Archive | `⌥A` | メール固有の整理 |
| Check for New Mail | `⌥G` | Get Mail。メール固有の受信確認 |

Apple MailとMicrosoft OutlookはForeground Applicationへ公式Shortcutを配送するLevel 1とする。GmailはChromeのActive Tabが`mail.google.com`の場合だけ公式Shortcutへ配送するLevel 2とし、それ以外のTabではTriggerを消費しない。Gmailの文字キーShortcutは、Gmail側のキーボードショートカット設定がONであることを前提とする。

新着確認のApplication MappingはApple Mailの`⇧⌘N`、Microsoft Outlookの`⌃⌘K`を使う。Gmail Webには受信確認専用の公式Shortcutがないため、ページ再読み込みの`⌘R`を配送する。`⌘R`は各メールクライアントで返信操作として定着しているためSuggested Triggerにはせず、QuickDrawのOption領域にある`⌥G`からのみ変換する。

## 7. OS操作

QuickDrawのSystem対象は、アプリ内部の一般的なメニュー操作ではなく、macOSが提供するワークスペース／ウインドウ操作である。Phase 1ではすべてLevel 0として扱い、QuickDrawは現在値と推奨値を表示して純正設定への導線だけを提供する。キーイベントの登録、消費、再配送やPreferenceへの書き込みはしない。

### 実行Level

QuickDraw自身の画面操作は外部Applicationへ配送するActionではないため、Level 0〜4とは別の`internal` deliveryとして扱う。通常のApplication Menuへ割り当て、QuickDrawがForegroundの時だけ有効にする。Global HotKeyへは登録せず、QuickDrawの起動やForeground化はランチャー製品Hakenへ委ねる。

通常利用ではAction InspectorをTriggerとApplication Mappingへ集中させる。Dry Run、Actionテスト、実行方式、Trigger登録詳細、ルーティングログはSettingsのDeveloper ModeがONの場合だけ表示する。アクセシビリティとプライバシーはInformationへ集約し、Developer ModeをOFFにした時は隠れたDry Runが残らないよう同時に解除する。

| QuickDraw内部Action | Shortcut |
|---|---|
| Meeting | `⌥M` |
| Chat | `⌥C` |
| Mail | `⌥E` |
| Development | `⌥D` |
| Browser | `⌥B` |
| Finder | `⌥F` |
| macOS | `⌥S` |
| Applications | `⌥A` |
| Information | `⌥I` |
| Settings | `⌘,` |
| Shortcut Guide | `⌥/` |
| Pause / Resume | `⇧⌥P` |
| Last Used Application Target Settings | `⇧⌥A` |
| Close Window | `⌘W` |
| Quit | `⌘Q` |

数字が上がるほどQuickDrawの介入度と保守コストが増える。Actionは、安定して目的を達成できる最も低いLevelで実装する。

| Level | 名称 | 実行方式 | 例 |
|---|---|---|---|
| 0 | Reference | 現在値を参照し、編集は公式設定画面へ委譲する | macOS Mission Control |
| 1 | Shortcut Remap | QuickDrawがTriggerを受け、公式Shortcutへリマップして対象アプリへ配送する | Finder、Zoom、Teams |
| 2 | Adapter | 対象、画面、URLなどを判定し、アプリ固有の経路で配送する | Google Meet、Browser Adapter |
| 3 | Accessibility | 公式ShortcutがないActionをAXで直接実行する | メニュー項目、ボタン、パネル操作 |

「Level 1で公式ショートカットを上書きする」ではなく、「公式ショートカットへリマップする」と表現する。Application側のShortcut設定は変更せず、QuickDrawが入力Triggerを公式Shortcutへ変換して配送するためである。同様にLevel 3は「AXでショートカットを設定する」のではなく、「AXでActionを直接実行する」と表現する。

AXでApplicationの設定画面を操作し、Shortcutなどの永続設定自体を書き換える方式は、UI変更に弱く、QuickDraw終了後も意図しない設定を残し得る。現時点では次のLevel 4候補として分離し、原則採用しない。

| 暫定Level | 名称 | 実行方式 |
|---|---|---|
| 4 | AX Persistent Configuration | AXで別ApplicationのUIを操作し、永続設定を変更する |

Level 3とLevel 4の分離は未確定である。重要な論点は「Actionをその場で実行する一時的なAX操作」と「別Applicationへ永続的な設定変更を残すAX操作」のリスク差だが、独立LevelにするかLevel 3のsubtypeにするかは今後再検討する。Level 4を前提とした実装や抽象化は行わない。

現在の対応関係は、macOSがLevel 0、Finderと一般のネイティブApplicationがLevel 1、Google MeetとGmailがLevel 2である。将来Action Catalogへ`executionLevel`または`deliveryMethod`として表示できる整理だが、必要になるまでは永続化形式やCatalog schemaへ追加しない。

### System Actionの対象

- Mission Control
- Application Exposé
- 前／次のデスクトップ
- 特定デスクトップへの移動（今回のUIはDesktop 1〜5）
- ウインドウを左／右半分へ配置
- 最大化／復元
- 次のディスプレイへ移動
- デスクトップを表示
- Stage Manager関連操作

次はSystem拡張の対象外とする。

- Copy Style / Paste Style
- Show / Hide Inspector
- Show / Hide Toolbar
- Focus Search Field

これらは既存アプリのメニューショートカットとして尊重し、QuickDrawでは競合予約としてのみ認識する。

### `Command + 矢印`の現在の競合

主な競合はテキスト編集とFinderである。

| キー | テキスト入力中 | Finder |
|---|---|---|
| `⌘↑` | 文書の先頭へ移動 | 親フォルダを開く |
| `⌘↓` | 文書の末尾へ移動 | 選択項目を開く |
| `⌘←` | 現在行の先頭へ移動 | 特別な標準操作なし |
| `⌘→` | 現在行の末尾へ移動 | 特別な標準操作なし |

Shift付きも範囲選択として定着している。

| キー | 現在の意味 |
|---|---|
| `⇧⌘↑` | 現在位置から文書先頭まで選択 |
| `⇧⌘↓` | 現在位置から文書末尾まで選択 |
| `⇧⌘←` | 現在位置から行頭まで選択 |
| `⇧⌘→` | 現在位置から行末まで選択 |

QuickDrawの原則から見ると、テキスト／カーソル操作とFinder固有操作がCommandを共有し、`⌃A`／`⌃E`とも意味が重複している。

### 原則準拠の再定義案

Finder側はOptionへ移す。

| Finder操作 | Before | After候補 |
|---|---:|---:|
| 親フォルダ | `⌘↑` | `⌥↑` |
| 選択項目を開く | `⌘↓` | `⌥↓` |

テキスト側はControl体系へ寄せる。

| テキスト操作 | Before | After候補 |
|---|---:|---:|
| 行頭 | `⌘←`または`⌃A` | `⌃A` |
| 行末 | `⌘→`または`⌃E` | `⌃E` |
| 文書先頭 | `⌘↑` | `⌃Home`相当 |
| 文書末尾 | `⌘↓` | `⌃End`相当 |
| 行頭まで選択 | `⇧⌘←` | `⇧⌃A`相当 |
| 行末まで選択 | `⇧⌘→` | `⇧⌃E`相当 |

Workspace全体へ作用する操作は、Shiftの「範囲大」を使って`Shift + Command + 矢印`へ割り当てる。`Command + 矢印`は既存のテキスト／アプリ操作へ返す。

| OS操作 | macOS標準 | 純正設定の推奨値 |
|---|---:|---:|
| Mission Control | `⌃↑`または`F3` | `⇧⌘↑` |
| Application Exposé | `⌃↓` | `⇧⌘↓` |
| 前のデスクトップ | `⌃←` | `⇧⌘←` |
| 次のデスクトップ | `⌃→` | `⇧⌘→` |

これはWorkspaceを「範囲大」として一貫して表現する一方、macOSユーザーに定着した`Shift + Command + 矢印`のテキスト範囲選択を置き換える大胆な変更である。QuickDrawはこれらのキーを横取り・再配送せず、ユーザーがmacOSの「キーボードショートカット」で明示的に設定した場合だけ有効になる。

### 追加するLevel 0推奨値

純正デフォルトを出発点にはせず、修正版の境界へActionの意味を当てはめて推奨値を決める。Workspaceの移動は既存4 Actionと同じ`Command`領域、小さなSystem UIと現在のウインドウだけへ作用する配置操作は`Command + Control`領域に置く。広く定着したデスクトップ表示の`F11`だけは既存文化を優先する。

| OS操作 | 純正設定の推奨値 | 方針 |
|---|---:|---|
| デスクトップを表示 | `F11` | 定着した既存文化を優先 |
| 通知センター | `⌃⌘N` | 小さなSystem UIを`Command + Control`へ配置 |
| おやすみモード | `⌃⌘D` | 小さなSystem UIを`Command + Control`へ配置 |
| Stage Manager | `⌃⌘S` | System UI切替を`Command + Control`へ配置 |
| ウインドウを画面いっぱいにする | `⌃⌘↑` | 現在のウインドウという範囲小と拡張方向を合成 |
| ウインドウを左半分に配置 | `⌃⌘←` | 現在のウインドウと配置方向を合成 |
| ウインドウを右半分に配置 | `⌃⌘→` | 現在のウインドウと配置方向を合成 |
| Desktop 1〜5へ直接移動 | `⌘1〜5` | Workspaceの直接移動を`Command`領域に配置 |

QuickDrawはこれらを実行しないため、Level 0の推奨値とQuickDrawのアプリ用Triggerは重複設定を禁止しない。実際の競合と優先順位はmacOS純正設定側で決まる。`⌃⌘N`はFinderの「選択項目から新規フォルダ」やTerminalの「同じコマンドで新規ウインドウ」、`⌃⌘D`は選択単語の「調べる」を置き換える可能性がある。最大化／復元のトグル、次のディスプレイ、Desktop 6以降は今回追加しない。

## 8. Finder

Finderは「OS機能」ではなくネイティブアプリとして扱う。QuickDrawが新しく共通化するFinder ActionはOption領域に置く。

| Finder Action | QuickDraw候補 |
|---|---:|
| Back／Forward | `⌥]` / `⇧⌥]` |
| Parent Folder | `⌥↑` |
| Open Selected Item | `⌥↓` |
| Downloads | `⌥L` |
| Home | `⌥H` |
| Desktop | `⌥D` |
| New Folder | `⌥N` |
| Quick Look | `⌥Y`、または既存`Space`を尊重 |
| Toggle Sidebar | `⇧⌥S` |
| Toggle Path Bar | `⇧⌥P` |
| Toggle Hidden Files | `⇧⌥.` |

Quick Lookの`Space`のように強く定着した操作は、無理にOptionへ変更しない。「Finderだから全部Option」ではなく、「QuickDrawで新しく共通化するFinder ActionはOption」が正確な境界である。

## 9. System設定とApplication Enablementで表現する

Finderは既存のApplication Enablementへ追加する。macOS操作はQuickDraw Targetとして有効化せず、純正のSystem Settingsで管理する。

Applications画面には次のSystemセクションを追加する。

```text
System
  macOS          System Settingsで管理
  Finder         OFF
```

Finderは通常のApplication Targetとして扱う。

```text
Finder
com.apple.finder
QuickDrawの対象: OFF
```

macOSは実行Targetではなく、純正設定の参照・編集導線として扱う。

```text
macOS
System Settings
現在のShortcutを表示
編集時はKeyboard Shortcuts > Mission Controlを開く
```

### デフォルトと互換性

- Meeting、Chat、Mail、Development、Browserは通常のForeground Application Targetとして扱う。
- FinderはOFFをデフォルトにし、アップデート時も自動でONにしない。
- macOS ActionのTriggerはQuickDrawへ登録しない。過去に保存されたmacOS有効状態があっても無視する。
- macOSの純正Shortcutは読み取り専用のbest-effort検出とし、QuickDrawからPreferenceを書き換えない。
- 既存ユーザーのCustom Trigger、Clear済みTrigger、Applicationごとの有効状態を無断で上書きしない。
- Phase 1のSuggested Trigger変更を実装するときは、既存設定の保持、変更一覧のpreview、Restore Suggested Triggerを含む移行仕様を別途決める。

これにより、通常ユーザーの`⌘←`行頭移動などは一切変わらない。

### 適用時の意味

Finder ON:

- FinderがForegroundのときだけTriggerを消費する。
- `⌥↑`で親フォルダ、`⌥↓`で選択項目を開く。
- `⌥H/D/L`でHome／Desktop／Downloadsへ移動する。
- Finder以外では完全に素通しする。

macOS純正設定:

- `⇧⌘↑`でMission Controlを開く。
- `⇧⌘↓`でApplication Exposéを開く。
- `⇧⌘←/→`で前／次のデスクトップへ移動する。
- Workspace、System切替、ウインドウ配置、Desktop 1〜5の現在値と推奨値を比較する。
- Foregroundアプリに関係なくmacOS自身がSystem操作を処理する。
- `Command + 矢印`による既存のテキスト／アプリ操作は維持する。
- `Shift + Command + 矢印`によるテキスト範囲選択は使えなくなる。
- QuickDrawは現在値と推奨値の一致を表示し、変更操作ではSystem Settingsを開く。

### ルーティング

```text
Finder Action
  ForegroundがFinder
    → 実行して消費
  それ以外
    → 素通し

macOS Action
  QuickDrawにはTriggerを登録しない
    → 常に素通し
  純正Shortcutが設定済み
    → macOSが直接実行
```

Finderの適用状態はApplication設定で保存・解除する。macOSの現在値は`com.apple.symbolichotkeys`からbest-effortで参照し、編集はSystem Settingsへ委譲する。

## 10. 実装前に検証すること

- Option + 英字が各キーボード配列の特殊文字入力と競合する影響。
- macOSのSymbolic Hotkey IDが各対応OSで読み取れるか。
- System Settingsへの遷移が各対応OSでKeyboard Shortcutsへ到達するか。
- Finderの各ActionをShortcut配送、Apple Events、Accessibilityのどれで安定実行するか。
- Level 0から先へ進める場合に、Stage Manager、特定デスクトップ、次のディスプレイへの移動に安定した実行経路があるか。
- Target-aware TriggerをAction、Target、Adapterのどの層に保持するか。

## 11. 参考資料

- [Apple: Mac keyboard shortcuts](https://support.apple.com/en-us/102650)
- [Apple: Work in multiple spaces on Mac](https://support.apple.com/guide/mac-help/work-in-multiple-spaces-mh14112/mac)
- [Apple: Move and arrange app windows on Mac](https://support.apple.com/guide/mac-help/mchl9674d0b0/mac)
