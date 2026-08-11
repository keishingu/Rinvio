# QuickDraw ショートカット設計原則と System / Finder opt-in 設計

- ステータス: Proposed / 未実装
- 更新日: 2026-08-11
- 対象: QuickDrawが提供するSuggested Triggerと将来のSystem / Finder Adapter

> この文書は将来の設計方針であり、現在のBuilt-in Action、Default Trigger、Adapter実装を変更したものではない。実装時は移行設計と実機検証を別途行う。

## 1. 背景

macOSの修飾キーには、歴史的に複数の体系が同居している。特にOptionは「alternative」と説明されることが多いが、何に対する代替なのかが操作やアプリによって異なり、QuickDrawのTriggerを一貫して配置する基準にはしにくい。

QuickDrawでは、Optionを「アプリ内のあらゆるメニュー操作」へ広げない。Optionは、QuickDrawがアプリを横断して呼び出す**アプリレベルの意味操作**に使う。既存アプリ内のCopy Style、Paste Style、Inspector、ToolbarなどをQuickDraw流に再配置する意図はない。

この原則は、既存世界をすべて再配線する憲法ではない。QuickDrawが新しく提供するTriggerを、意味に沿って迷わず配置するための設計原則である。すでに広く定着したショートカットは、原則より既存文化を優先できる。

## 2. 修正版の境界

| レイヤー | 対象 | 例 |
|---|---|---|
| `Control` | テキスト、CUI、カーソル、エディタ操作 | 行移動、コメント、Format、Rename |
| `Command` | 定着したOS / GUI共通操作 | Copy、Reload、Close、Quit |
| `Option` | QuickDrawが統一するネイティブアプリ操作 | Mute、New Session、Finder操作 |
| `Command + Option` | Webアプリ、ネストされたアプリ／サブシステム | 将来のGoogle Meet、Web版Zoom、DevTools |
| `Shift` | 逆方向、範囲、反転、強制版 | Previous、選択範囲、Redo、Hard Reload、Close All |

### 適用ルール

1. Actionの意味がテキスト編集、CUI、カーソル、エディタ操作ならControl領域に置く。
2. Copy、Reload、Close、Quitのように定着したGUI共通操作はCommand文化を尊重する。
3. QuickDrawが複数のネイティブアプリ間で意味を統一するActionはOption領域に置く。
4. Webアプリやアプリ内サブシステムのActionはCommand + Option領域を候補とする。
5. Shiftは「逆方向」だけでなく、範囲、反転、Rubyの `!` に相当する強制版を表す。
6. FinderはOSそのものではなく、ネイティブアプリとしてOption領域に置く。
7. 既存アプリの内部メニューを網羅的に再配置しない。QuickDrawが扱わない既存ショートカットは、競合検出の予約情報として認識する。

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

## 6. OS操作として検討する対象

QuickDrawのSystem拡張対象は、アプリ内部の一般的なメニュー操作ではなく、macOSが提供するワークスペース／ウインドウ操作である。

- Mission Control
- Application Exposé
- 前／次のデスクトップ
- 特定デスクトップへの移動
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

空いたCommand + 矢印をSystem操作へ割り当てる。

| OS操作 | macOS標準 | macOS Target ON |
|---|---:|---:|
| Mission Control | `⌃↑`または`F3` | `⌘↑` |
| Application Exposé | `⌃↓` | `⌘↓` |
| 前のデスクトップ | `⌃←` | `⌘←` |
| 次のデスクトップ | `⌃→` | `⌘→` |

これは直感的だが、macOSユーザーに定着したテキスト移動を置き換える大胆な変更である。通常のデフォルトにはせず、後述するmacOS Targetの明示的opt-inとしてのみ提供する。

ウインドウ配置、最大化／復元、次のディスプレイ、デスクトップ表示、Stage ManagerのTriggerは、この文書では確定しない。既存標準、競合、対称性、実行経路を個別に監査してから決める。

## 7. Finder

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

## 8. Application Enablementで表現する

既存のApplication設定にmacOSとFinderを追加し、それぞれの有効／無効の組み合わせで適用範囲を表現する。

| macOS | Finder | 状態 |
|---:|---:|---|
| OFF | OFF | 現在相当。アプリだけQuickDraw化 |
| OFF | ON | Finder操作も原則準拠 |
| ON | OFF | OS操作だけ原則準拠 |
| ON | ON | 全体を原則準拠 |

Applications画面には次のSystemセクションを追加する。

```text
System
  macOS          OFF
  Finder         OFF
```

Finderは通常のApplication Targetとして扱う。

```text
Finder
com.apple.finder
QuickDrawの対象: OFF
```

macOSはForegroundアプリを持たない擬似Targetとして扱う。

```text
macOS
System-wide
QuickDrawの対象: OFF
```

### デフォルトと互換性

- Meeting、Chat、Development、Browserは従来どおり対象とする。
- FinderとmacOSはOFFをデフォルトにする。
- アップデート時も自動でONにしない。
- ユーザーが明示的に有効化した状態だけを保存する。
- 既存ユーザーのCustom Trigger、Clear済みTrigger、Applicationごとの有効状態を無断で上書きしない。
- Phase 1のSuggested Trigger変更を実装するときは、既存設定の保持、変更一覧のpreview、Restore Suggested Triggerを含む移行仕様を別途決める。

これにより、通常ユーザーの`⌘←`行頭移動などは一切変わらない。

### ONにしたときの意味

Finder ON:

- FinderがForegroundのときだけTriggerを消費する。
- `⌥↑`で親フォルダ、`⌥↓`で選択項目を開く。
- `⌥H/D/L`でHome／Desktop／Downloadsへ移動する。
- Finder以外では完全に素通しする。

macOS ON:

- `⌘↑`でMission Controlを開く。
- `⌘↓`でApplication Exposéを開く。
- `⌘←/→`で前／次のデスクトップへ移動する。
- Foregroundアプリに関係なくSystem操作を優先する。
- 従来の`Command + 矢印`によるテキスト移動は使えなくなる。

macOSをONにするときだけ、競合の確認画面を必須にする。

> macOSをQuickDrawの対象にすると、OS操作がすべてのアプリで優先されます。`⌘↑/↓/←/→`など、現在テキスト編集やFinderで使われているショートカットが置き換わります。

有効化前に変更一覧を表示し、同じ画面から即座にOFFへ戻せるようにする。

### ルーティング

```text
Finder Action
  ForegroundがFinder
    → 実行して消費
  それ以外
    → 素通し

macOS Action
  macOS TargetがON
    → Foregroundに関係なく実行して消費
  OFF
    → 素通し
```

macOSとFinderの適用状態は、現在のApplication設定で説明、保存、解除できる。

## 9. 実装前に検証すること

- Option + 英字が各キーボード配列の特殊文字入力と競合する影響。
- macOS / Finderの各候補Triggerが現行macOSで登録・消費できるか。
- `Command + 矢印`をSystem-wideで奪う警告が十分に理解されるか。
- Finderの各ActionをShortcut配送、Apple Events、Accessibilityのどれで安定実行するか。
- Stage Manager、特定デスクトップ、次のディスプレイへの移動に安定した実行経路があるか。
- Target-aware TriggerをAction、Target、Adapterのどの層に保持するか。

## 10. 参考資料

- [Apple: Mac keyboard shortcuts](https://support.apple.com/en-us/102650)
- [Apple: Work in multiple spaces on Mac](https://support.apple.com/guide/mac-help/work-in-multiple-spaces-mh14112/mac)
- [Apple: Move and arrange app windows on Mac](https://support.apple.com/guide/mac-help/mchl9674d0b0/mac)
