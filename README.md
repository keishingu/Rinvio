# QuickDraw PoC

頻出する会議ActionをForegroundのMicrosoft Teams、Zoom Workplace、Chrome上のGoogle Meetへ配送するmacOS Utilityです。

- `F6 → Mute`
- `F7 → Camera`
- `F8 → Raise Hand`

## Scope

- Microsoft Teams / Zoom Workplace / Google Meetの公式ショートカットを15のActionへ変換
- Foreground target only
- Action-first native settings window with an application mapping inspector
- Editable global Triggers and per-application shortcut overrides with one-click default restore
- Versioned configuration persisted in Application Support
- Live Japanese / English display switching, persisted across launches
- Applications and privacy-safe Diagnostics views
- Menu bar status, non-delivery Dry Run, copied diagnostics, and redacted unified log
- No general key logging, polling, profiles, UI automation, or background routing

設計全体は [QuickDraw プロダクト・技術設計書](docs/quickdraw-product-design.ja.md) を参照してください。

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

1. 起動時に表示されるQuickDraw Windowで、ActionとTeams / Zoom / MeetのMappingを確認する。Windowを閉じた後はMenu Barの`Open QuickDraw…`から再表示できる。
   表示言語はToolbarの地球アイコンから日本語／Englishを切り替えられる。
2. 権限を与える前に確認する場合はAction Inspectorの`Dry Run`を有効にし、対象Application/Meet TabをForegroundにしてF6／F7／F8を押す。Dry Runはshortcutを送信しない。
3. 実配送を試す場合はInspectorまたはMenu Barの`Request Accessibility Permission…`を選ぶ。
4. System Settings → Privacy & Security → AccessibilityでQuickDraw PoCを許可する。
5. Google Meetを使う場合は、最初の判定時に表示されるAutomation promptでGoogle Chromeを許可する。
6. Dry Runを無効にし、対象Application/Meet TabをForegroundにしてF6／F7／F8を押す。

## Shortcut configuration

Action Inspectorから次を編集できます。

- `Trigger`: QuickDrawを呼び出すグローバルショートカット。Fキー、またはCommand / Control / Optionを含む組み合わせを使用する。
- `Application mapping`: Actionを各Applicationへ配送するショートカット。Teams / Zoom / Meet側で既定値を変更した場合にOverrideする。
- `Restore Default`: 個別のOverrideを削除してBuilt-in Catalogへ戻す。
- `Restore All Defaults for This Action`: TriggerとそのActionの全Application Mappingを確認後にまとめて戻す。

設定は `~/Library/Application Support/QuickDraw/configuration.json` にschema version付きで保存されます。Built-inのDefault値は保存ファイルへ複製せず、Overrideだけを保存します。

F6 / F7 / F8以外のBuilt-in ActionはTrigger未割り当てです。必要なActionだけにTriggerを設定するため、追加Actionの登録だけでグローバルショートカットが増えたり衝突したりすることはありません。

MacのKeyboard設定でFunction Keyがsystem functionとして動く場合は、`fn`を併用するか「Use F1, F2, etc. keys as standard function keys」を有効にします。

## Built-in mappings

| Action | Trigger | Teams | Zoom | Google Meet |
|---|---|---|---|---|
| Mute Toggle | F6 | `⌘⇧M` | `⌘⇧A` | `⌘D` |
| Camera Toggle | F7 | `⌘⇧O` | `⌘⇧V` | `⌘E` |
| Raise Hand Toggle | F8 | `⌘⇧K` | `⌥Y` | `⌃⌘H` |
| Switch Camera | — | — | `⌘⇧N` | — |
| Show Chat | — | — | `⌘⇧H` | `⌃⌘C` |
| Show Participants | — | — | `⌘U` | `⌃⌘P` |
| Captions Toggle | — | `⌘⇧A` | — | `C` |
| Share Screen | — | `⌘⇧E` | `⌘⇧S` | `⌃⌘T` |
| Picture in Picture | — | — | — | `⇧M` |
| Reaction: 👍 | — | — | `⌥⌘5` | — |
| Reaction: ❤️ | — | — | `⌥⌘6` | — |
| Reaction: 👏 | — | — | `⌥⌘4` | — |
| Reaction: 😂 | — | — | `⌥⌘7` | — |
| Reaction: 😮 | — | — | `⌥⌘8` | — |
| Reaction: 🎉 | — | — | `⌥⌘9` | — |

`—`はそのApplicationの公式ショートカットが確認できていない状態です。実行時はキーを送らず、未対応として安全に終了します。既定値は[Microsoft Teams](https://support.microsoft.com/en-US/Accessibility/teams/keyboard-shortcuts-for-microsoft-teams)、[Zoom Workplace](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0067050)、[Google Meet](https://support.google.com/meet/answer/9298571)の公式資料に基づきます。Application側でショートカットを変更した場合や独自に割り当てた場合は、QuickDrawのAction Inspectorから同じ値へOverrideできます。

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
