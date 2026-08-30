# RinvioのDeveloper ID署名とnotarization

RinvioはMac App Storeではなく、Developer ID Applicationで署名し、Appleのnotary serviceで検証したDMGとして直接配布する。初期公開はアカウント登録やLicense Keyのない無料配布とする。GitHub Actionsの`Build notarized Rinvio DMG`はUniversal appのbuild、署名、DMG作成、notarization、staple、checksum作成までを行う。

配布判断の背景は[ADR-0003](adr/0003-macos-direct-distribution-after-app-store-rejection.md)、決済・licenseの検討は[GitHub Issue #13](https://github.com/keishingu/QuickDraw/issues/13)を参照する。

## 配布物と識別子

| 項目 | 値 |
|---|---|
| Application | `Rinvio.app` |
| Bundle ID | `com.keishingu.rinvio` |
| DMG | `Rinvio-macos-universal.dmg` |
| Architecture | `arm64`, `x86_64` |
| Minimum macOS | 15.0 |
| Signing | Developer ID Application + Hardened Runtime |
| Entitlement | Apple Events automationのみ |

旧QuickDraw版の設定がある場合、Rinvio側の設定が存在しない初回起動時だけ`~/Library/Application Support/QuickDraw/configuration.json`から`~/Library/Application Support/Rinvio/configuration.json`へコピーする。Custom Trigger、Clear済みTrigger、Application Enablementを保持し、旧ファイルは削除しない。壊れた旧設定は移行せず、安全な既定値で起動する。

## 必要なApple Developer資材

1. `Developer ID Application`証明書
2. 証明書と秘密鍵を含むpassword付き`.p12`
3. App Store Connect Team API Keyの`.p8`
4. Apple Developer Team ID
5. API Key IDとIssuer ID

installer packageは使わないため、`Developer ID Installer`証明書は不要。

## GitHub Repository Variables

RepositoryのSettings → Secrets and variables → Actions → Variablesへ登録する。

| Name | Value |
|---|---|
| `APPLE_TEAM_ID` | Developer ID Application証明書のTeam ID |
| `APP_STORE_CONNECT_KEY_ID` | Team API KeyのKey ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Team API KeyのIssuer ID |

## GitHub Repository Secrets

| Name | Value |
|---|---|
| `DEVELOPER_ID_APPLICATION_P12_BASE64` | `.p12`全体をbase64化した値 |
| `DEVELOPER_ID_APPLICATION_P12_PASSWORD` | `.p12`のexport password |
| `APP_STORE_CONNECT_API_KEY_P8_BASE64` | `.p8`全体をbase64化した値 |

秘密値をcommand line引数へ含めず、標準入力から登録する。

```sh
base64 -i DeveloperIDApplication.p12 \
  | gh secret set DEVELOPER_ID_APPLICATION_P12_BASE64 --repo keishingu/QuickDraw

gh secret set DEVELOPER_ID_APPLICATION_P12_PASSWORD --repo keishingu/QuickDraw

base64 -i AuthKey_KEYID.p8 \
  | gh secret set APP_STORE_CONNECT_API_KEY_P8_BASE64 --repo keishingu/QuickDraw
```

`.p12`、`.p8`、password、base64文字列をrepositoryへcommitしない。

## Workflowの使い方

1. GitHub Actionsで`Build notarized Rinvio DMG`を開く。
2. 検証対象branchを選ぶ。
3. `version`へmarketing versionを入力する。
4. 初回確認では`publish`をOFFのまま実行する。
5. 成功後、7日間保持される`Rinvio-macos-notarized-*` artifactをdownloadして実機確認する。
6. Download、Support、Privacyの公開ページと実機検証が整った後だけ、mainで`publish`をONにして実行する。

`publish`はmain以外では失敗する。VariablesまたはSecretsが不足している場合、Developer ID identityがTeam IDと一致しない場合、notarizationが`Accepted`以外の場合もartifactやReleaseを公開せず失敗する。

公開後の最新版DMGは次の固定URLから取得できる。

```text
https://github.com/keishingu/QuickDraw/releases/latest/download/Rinvio-macos-universal.dmg
```

LP、README、Support pageはこのURLを参照する。GitHub Releaseのtagが変わってもリンクの更新は不要である。

## Website公開

公開サイトは`docs/site/`を正本とし、<https://keishingu.github.io/QuickDraw/>で配信する。現在のGitHub Pages sourceは`gh-pages` branchであり、mainへのmergeだけではサイトへ反映されない。

初回無料公開は次の順序で行う。

1. mainで`Build notarized Rinvio DMG`を`publish: ON`にして実行し、GitHub Releaseを作成する。
2. `releases/latest/download/Rinvio-macos-universal.dmg`が200を返すことを確認する。
3. `docs/site/`の内容を`gh-pages`へ公開する。
4. 本番LPのDownload、Support、Privacyリンクを確認する。

Releaseより先にLPを更新するとDownloadボタンが未公開URLを指すため、この順序を入れ替えない。

## Workflowが行うこと

1. 必須VariablesとSecretsを検証する
2. 一時KeychainへDeveloper ID Application証明書をimportする
3. format lint、unit test、開発用bundle検証を行う
4. Swift Packageをarm64とx86_64でbuildし、Universal executableへ結合する
5. `Rinvio.app`をHardened Runtime、Apple Events entitlement、secure timestamp付きで署名する
6. `dmgbuild`でApplicationsへのdrag-and-drop DMGを作成し署名する
7. DMGをnotary serviceへ提出し、`Accepted`を明示的に確認する
8. ticketをstapleし、Gatekeeper、署名、DMGを検証する
9. staple後のDMGからSHA-256 checksumを作る
10. notarized artifactを保存し、明示指定時だけGitHub Releaseを作る
11. 一時Keychainを削除する

## ローカル検証

通常の開発用bundleは次で検証する。

```sh
Scripts/verify.sh
open .build/app/Rinvio.app
```

Developer ID証明書と`dmgbuild`があるMacでは、署名済みDMGをローカルでも作成できる。

```sh
python3 -m pip install -r Scripts/requirements-dmg.txt

BUILD_NUMBER=1 \
MARKETING_VERSION=1.0.0 \
SIGNING_IDENTITY='Developer ID Application: Example (TEAMID)' \
Scripts/build-direct-release.sh
```

notarization済みDMGは次で確認する。

```sh
hdiutil verify build/release/Rinvio-macos-universal.dmg
codesign --verify --verbose=2 build/release/Rinvio-macos-universal.dmg
xcrun stapler validate build/release/Rinvio-macos-universal.dmg
spctl \
  --assess \
  --type open \
  --context context:primary-signature \
  --verbose=4 \
  build/release/Rinvio-macos-universal.dmg
```

さらにDMGをFinderで開き、RinvioをApplicationsへドラッグし、通常起動できることを確認する。初回起動ではInput Monitoring、Accessibility、Google Chrome利用時のAutomationについて、表示内容と許可後の動作を確認する。

Bundle IDが旧版から変わるため、既に開発版を使っていたMacではInput MonitoringとAccessibilityをRinvioへ改めて許可する必要がある。旧QuickDraw版の権限項目は不要になった時点でSystem Settingsから削除できる。

現時点のworkflowは署名済み配布物を安全に生成し、明示指定時だけ無料公開するところまでを対象とする。更新は最新版DMGでApplications内のRinvioを置き換える。license発行、購入者限定download、automatic updateは将来必要になった時点で別途実装する。

## 公式資料

- [Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)
- [GitHub Actions secrets](https://docs.github.com/en/actions/concepts/security/secrets)
