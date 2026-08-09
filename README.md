# QuickDraw PoC

`F6 → Mute` をForegroundのMicrosoft Teams、Zoom Workplace、Chrome上のGoogle Meetへ配送する縦切りPoCです。

## Scope

- Microsoft Teams: `⌘⇧M`
- Zoom Workplace: `⌘⇧A`
- Google Meet in Google Chrome: `⌘D`
- Foreground target only
- Menu bar status, non-delivery Dry Run, copied diagnostics, and redacted unified log
- No general key logging, polling, persistence, profiles, reactions, or background routing

設計全体は [QuickDraw プロダクト・技術設計書](docs/quickdraw-product-design.ja.md) を参照してください。

## Build and test

```sh
Scripts/verify.sh
open '.build/app/QuickDraw PoC.app'
```

`Scripts/verify.sh` はformat lint、23件以上のunit test、app bundle生成、Info.plist、code signatureをまとめて検証します。

再ビルド後もTCC権限を安定させたい場合は、利用可能なDeveloper IDまたはApple Development証明書名を指定します。

```sh
QUICKDRAW_CODE_SIGN_IDENTITY='Apple Development: Your Name (TEAMID)' Scripts/build-app.sh debug
```

指定しない場合はローカルPoC用のad-hoc署名になります。署名が変わるとmacOSがPermissionを再要求する場合があります。

## First run

1. Menu barのQuickDraw iconを開く。
2. 権限を与える前に確認する場合は`Dry Run`を有効にし、対象Application/Meet TabをForegroundにしてF6を押す。Dry Runはshortcutを送信しない。
3. 実配送を試す場合は`Request Accessibility Permission…`を選ぶ。
4. System Settings → Privacy & Security → AccessibilityでQuickDraw PoCを許可する。
5. Google Meetを使う場合は、最初の判定時に表示されるAutomation promptでGoogle Chromeを許可する。
6. Dry Runを無効にし、対象Application/Meet TabをForegroundにしてF6を押す。

MacのKeyboard設定でF6がsystem functionとして動く場合は、`fn` + `F6`を使うか「Use F1, F2, etc. keys as standard function keys」を有効にします。

## Manual verification matrix

各Targetで会議に参加し、unmutedから30回実行して以下を記録します。

| Target | Foreground condition | Expected | 30 cycles | Focus stolen | Duplicate/stuck key |
|---|---|---|---|---|---|
| Teams | Teams meeting window | `⌘⇧M`相当でtoggle |  |  |  |
| Zoom | Zoom meeting window | `⌘⇧A`相当でtoggle |  |  |  |
| Meet | Chrome active tab host = `meet.google.com` | `⌘D`相当でtoggle |  |  |  |

追加のfailure checks:

- Chromeの非Meet Tabでは配送されない。
- TextEdit等の非対応Appでは配送されない。
- Accessibility拒否時はMenu Barに理由が表示される。
- Chrome Automation拒否時はMeetだけ失敗し、Teams/Zoomには影響しない。
- QuickDrawのMenuからTestしても最後に使っていた外部AppをTargetとして扱う。

## Diagnostics

通常の成功/失敗とlatencyはMenu Barに表示されます。`Copy Diagnostics`で直近20件の判定結果、F6登録、権限状態をコピーできます。詳細はConsole.appでsubsystem `dev.actionrouter.quickdraw-poc` を絞り込みます。

記録対象はAction route、Application bundle ID、Meetか否かの分類、Execution Method、Result、Latencyです。Full URL、Meet以外のhost、Tab title、Meeting code、入力内容は記録しません。
