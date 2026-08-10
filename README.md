# QuickDraw PoC

アプリごとに異なる頻出操作を共通Actionへ変換し、Foregroundの対象アプリへ配送するmacOS Utilityです。

- `⌘⌥M → Mute`
- `⌘⌥C → Camera`
- `⌘⌥H → Raise Hand`
- `⌘⌥J → Jump to Conversation`
- `⌘⌥N → New Session`
- `⌘⌥R → Hard Reload`

## Scope

- Meeting / Chat / Development / Browserに分類した40のBuilt-in Action
- Microsoft Teams / Zoom Workplace / Google Meet / Slack / Discord / Cairn / Codex / Claude / Visual Studio Code / Cursor / Terminal / iTerm2 / Safari / Google Chromeの既定ショートカットを共通Actionへ変換
- Foreground target only
- Action-first native settings window with an application mapping inspector
- Editable global Triggers and per-application shortcut overrides with one-click default restore
- Foreground Application向けのShortcut Guideを`⌘⌥`長押しで表示
- Versioned configuration persisted in Application Support
- Versioned Built-in Catalog bundled as JSON
- Live Japanese / English display switching, persisted across launches
- Applications and privacy-safe Diagnostics views
- Dock app and Menu Bar status, non-delivery Dry Run, copied diagnostics, and redacted unified log
- No general key logging, polling, profiles, UI automation, or background routing

設計全体は [QuickDraw プロダクト・技術設計書](docs/quickdraw-product-design.ja.md) を参照してください。Browser ExtensionをQuickDraw.appのAdapterとして段階的モノレポで管理する判断は [ADR-0001](docs/adr/0001-browser-extension-adapter-and-monorepo.md) に記録しています。

## Build and test

```sh
Scripts/verify.sh
open '.build/app/QuickDraw PoC.app'
```

`Scripts/verify.sh` はformat lint、unit test、app bundle生成、Info.plist、code signatureをまとめて検証します。

再ビルド後もTCC権限を安定させるため、`Scripts/build-app.sh` は利用可能なApple Development証明書を自動選択します。明示的に指定する場合は次の環境変数を使います。

```sh
QUICKDRAW_CODE_SIGN_IDENTITY='Apple Development: Your Name (TEAMID)' Scripts/build-app.sh debug
```

証明書が見つからない場合だけローカルPoC用のad-hoc署名へフォールバックします。adhoc署名では、再ビルド後にmacOSがPermissionを再要求する場合があります。

## First run

1. 起動時に表示されるQuickDraw Windowで、Meeting / Chat / Development / BrowserのActionと各ApplicationのMappingを確認する。Windowを閉じた後はMenu Barの`Open QuickDraw…`から再表示できる。
   表示言語はToolbarの地球アイコンから日本語／Englishを切り替えられる。
2. 権限を与える前に確認する場合はAction Inspectorの`Dry Run`を有効にし、対象Application/Meet TabをForegroundにして設定済みTriggerを押す。Dry Runはshortcutを送信しない。
3. 実配送を試す場合はInspectorまたはMenu Barの`Request Accessibility Permission…`を選ぶ。
4. System Settings → Privacy & Security → AccessibilityでQuickDraw PoCを許可する。
5. Google Meetを使う場合は、最初の判定時に表示されるAutomation promptでGoogle Chromeを許可する。
6. Dry Runを無効にし、対象Application/Meet TabをForegroundにして設定済みTriggerを押す。

## Shortcut Guide

対応ApplicationをForegroundにして`⌘⌥`を約0.6秒長押しすると、そのApplicationで現在利用できるQuickDraw Actionだけを画面中央のHUDへ表示します。`⌘⌥`を離すと閉じ、Modifierイベント自体は消費しません。`⌥1`などへ変更したTriggerも含め、現在のユーザー設定をそのまま表示します。

Sidebarの`Settings`から表示をON/OFFでき、`Preview`で最後に使った対応Application向けの内容を確認できます。設定はUserDefaultsへ保存します。

HUDには画面共有からの除外指定をベストエフォートで付与しています。ただしAppleは`NSWindow.SharingType.none`を現在legacyとし、キャプチャ除外目的には使わないよう案内しています。共有側ApplicationがScreenCaptureKitのFilterでQuickDrawを除外しない限り、すべての画面共有方式で非表示になる保証はありません。

## Shortcut configuration

Action Inspectorから次を編集できます。

- `Trigger`: QuickDrawを呼び出すグローバルショートカット。Fキー、またはCommand / Control / Optionを含む組み合わせを使用する。
- `Application mapping`: Actionを各Applicationへ配送するショートカット。Application側で既定値を変更した場合にOverrideする。
- `Restore Default`: 個別のOverrideを削除してBuilt-in Catalogへ戻す。
- `Restore All Defaults for This Action`: TriggerとそのActionの全Application Mappingを確認後にまとめて戻す。

設定は `~/Library/Application Support/QuickDraw/configuration.json` にschema version付きで保存されます。Built-inのDefault値は [`built-in-catalog.json`](Sources/QuickDrawCore/Resources/built-in-catalog.json) から読み込み、ユーザー設定にはOverrideだけを保存します。Action IDを維持しているため、既存のOverrideもそのまま引き継がれます。

Built-in ActionにはQuickDrawの名前空間として`⌘⌥` Triggerを割り当てています。TriggerはForeground Applicationのカテゴリ内で解決し、対応アプリまたはMeetタブでだけQuickDrawがキーを消費します。別カテゴリや対象外では元のキーイベントをそのままアプリ／macOSへ渡します。

Applicationの所属カテゴリが交差しないAction同士は、同じTriggerを再利用できます。一方、TeamsのようにMeetingとChatの両方へ所属するApplicationがあるカテゴリ間では、判定が曖昧になるため重複Triggerを設定できません。Google MeetではActive Tabを判定できるため、MeetタブならMeeting Action、それ以外のChromeタブならBrowser Actionを優先します。

macOS標準またはSystem Settingsで有効なショートカットと競合する場合、Action Inspectorに警告を表示します。これは使用禁止ではなく、対応アプリではQuickDrawが優先されることを示します。System Settingsの検出は非公開のPreference表現を読むbest-effort方式であり、既知の標準ショートカットカタログと組み合わせています。

## Built-in mappings

### Meeting

| Action | Trigger | Teams | Zoom | Google Meet |
|---|---|---|---|---|
| Mute Toggle | `⌘⌥M` | `⌘⇧M` | `⌘⇧A` | `⌘D` |
| Camera Toggle | `⌘⌥C` | `⌘⇧O` | `⌘⇧V` | `⌘E` |
| Raise Hand Toggle | `⌘⌥H` | `⌘⇧K` | `⌥Y` | `⌃⌘H` |
| Switch Camera | `⌘⌥X` | — | `⌘⇧N` | — |
| Show Chat | `⌘⌥O` | — | `⌘⇧H` | `⌃⌘C` |
| Show Participants | `⌘⌥P` | — | `⌘U` | `⌃⌘P` |
| Captions Toggle | `⌘⌥L` | `⌘⇧A` | — | `C` |
| Share Screen | `⌘⌥S` | `⌘⇧E` | `⌘⇧S` | `⌃⌘T` |
| Picture in Picture | `⌘⌥I` | — | — | `⇧M` |
| Leave Meeting | `⌘⌥G` | `⌘⇧H` | `⌘W` | `⌘[` |
| Reaction: 👍 | `⌘⌥1` | — | `⌥⌘5` | — |
| Reaction: ❤️ | `⌘⌥2` | — | `⌥⌘6` | — |
| Reaction: 👏 | `⌘⌥3` | — | `⌥⌘4` | — |
| Reaction: 😂 | `⌘⌥4` | — | `⌥⌘7` | — |
| Reaction: 😮 | `⌘⌥5` | — | `⌥⌘8` | — |
| Reaction: 🎉 | `⌘⌥6` | — | `⌥⌘9` | — |

### Chat

| Action | Trigger | Slack | Teams | Discord | Cairn |
|---|---|---|---|---|---|
| Jump to Conversation | `⌘⌥J` | `⌘K` | `⌘G` | `⌘K` | — |
| Search Messages | `⌘⌥F` | `⌘G` | `⌘E` | `⌘⇧F` | `⌘⇧F` |
| New Message | `⌘⌥W` | `⌘N` | `⌘N` | — | — |
| Previous Conversation | `⌘⌥Page Up` | `⌥↑` | — | `⌥↑` | `⌥↑` |
| Next Conversation | `⌘⌥Page Down` | `⌥↓` | — | `⌥↓` | `⌥↓` |
| Open Unreads | `⌘⌥U` | `⌘⇧A` | — | — | — |

### Development

| Action | Trigger | Codex | Claude | VS Code | Cursor | Terminal | iTerm2 |
|---|---|---|---|---|---|---|---|
| New Session | `⌘⌥N` | `⌘N` | `⌘N` | — | — | — | — |
| Toggle Terminal | `⌘⌥T` | `⌃\`` | — | `⌃\`` | `⌃\`` | — | — |
| New Terminal | `⌘⌥A` | — | — | `⌃⇧\`` | `⌃⇧\`` | — | — |
| Next Terminal | `⌘⌥.` | — | — | `⇧⌘]` | `⇧⌘]` | `⌃Tab` | — |
| Previous Terminal | `⌘⌥,` | — | — | `⇧⌘[` | `⇧⌘[` | `⌃⇧Tab` | — |
| Split Terminal | `⌘⌥\` | — | — | `⌘\` | `⌘\` | `⌘D` | `⌘D` |
| Focus Sidebar | `⌘⌥←` | — | — | `⌘0` | `⌘0` | — | — |
| Focus Main Column | `⌘⌥→` | — | — | `⌘1` | `⌘1` | — | — |
| Focus Terminal | `⌘⌥↓` | `⌃\`` | — | `⌃\`` | `⌃\`` | — | — |
| Command Palette | `⌘⌥K` | `⌘K` | — | `⌘⇧P` | `⌘⇧P` | — | — |
| Quick Open | `⌘⌥Q` | `⌘P` | — | `⌘P` | `⌘P` | — | — |
| Keyboard Shortcuts | `⌘⌥B` | `⌘/` | — | — | — | — | — |

### Browser

| Action | Trigger | Safari | Google Chrome |
|---|---|---|---|
| Hard Reload | `⌘⌥R` | `⌘⌥R` | `⌘⇧R` |
| Next Tab | `⌘⌥]` | `⌃Tab` | `⌘⌥→` |
| Previous Tab | `⌘⌥[` | `⌃⇧Tab` | `⌘⌥←` |
| Reopen Closed Tab | `⌘⌥Z` | `⌘⇧T` | `⌘⇧T` |
| Open Downloads | `⌘⌥D` | `⌘⌥L` | `⌘⇧J` |
| Open Developer Tools | `⌘⌥E` | `⌘⌥I` | `⌘⌥I` |

`—`はそのApplicationのショートカットが確認できていない状態です。実行時はキーを送らず、未対応として安全に終了します。既定値は[Microsoft Teams](https://support.microsoft.com/en-US/Accessibility/teams/keyboard-shortcuts-for-microsoft-teams)、[Zoom Workplace](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0067050)、[Google Meet](https://support.google.com/meet/answer/9298571)、[Slack](https://slack.com/help/articles/201374536-Slack-keyboard-shortcuts-and-commands)、[Discord](https://support.discord.com/hc/en-us/articles/31232432266647-Discord-Commands-Shortcuts-and-Navigation-Guide)、[Visual Studio Code](https://code.visualstudio.com/docs/getstarted/keybindings)、[Terminal](https://support.apple.com/guide/terminal/keyboard-shortcuts-trmlshtcts/mac)、[iTerm2](https://iterm2.com/documentation/2.1/documentation-highlights.html)、[Safari](https://support.apple.com/guide/safari/keyboard-and-other-shortcuts-cpsh003/mac)、[Google Chrome](https://support.google.com/chrome/answer/157179)の資料、CairnのCommand Catalog、インストール済みCodexのCommand定義に基づきます。Application側でショートカットを変更した場合や独自に割り当てた場合は、QuickDrawのAction Inspectorから同じ値へOverrideできます。

SafariのDeveloper Toolsは、Safari設定の「Webデベロッパ用の機能を表示」が有効な場合に利用できます。VS CodeのKeyboard Shortcutsは既定値が2段階のChord (`⌘K` → `⌘S`) のため、単一Shortcutのみを配送する現在のCatalogでは未対応です。Application側で単一Shortcutを割り当てればQuickDrawからOverrideできます。

## Manual verification matrix

各Targetで会議に参加し、各Actionを30回実行して以下を記録します。

| Target | Foreground condition | Actions | 30 cycles each | Focus stolen | Duplicate/stuck key |
|---|---|---|---|---|---|
| Teams | Teams meeting window | Mute / Camera / Raise Hand |  |  |  |
| Zoom | Zoom meeting window | Mute / Camera / Raise Hand |  |  |  |
| Meet | Chrome active tab host = `meet.google.com` | Mute / Camera / Raise Hand |  |  |  |

追加のfailure checks:

- Chromeの非Meet Tabでは配送されない。
- TextEdit等の非対応Appでは配送されない。
- Accessibility拒否時はMenu Barに理由が表示される。
- Chrome Automation拒否時はMeetだけ失敗し、Teams/Zoomには影響しない。
- QuickDrawのMenuからTestしても最後に使っていた外部AppをTargetとして扱う。

## Diagnostics

通常の成功/失敗とlatencyはMenu Barに表示されます。`Copy Diagnostics`で直近20件の判定結果、割り当て済みTrigger、権限状態をコピーできます。詳細はConsole.appでsubsystem `dev.actionrouter.quickdraw-poc` を絞り込みます。

記録対象はAction route、Application bundle ID、Meetか否かの分類、Execution Method、Result、Latencyです。Full URL、Meet以外のhost、Tab title、Meeting code、入力内容は記録しません。
