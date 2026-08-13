# App Store screenshots

App Store Connectへ次の順序でアップロードする、実画面ベースのスクリーンショットです。

1. Meeting
2. Development
3. Applications
4. Browser
5. macOS
6. Information

## 出力

- 日本語: `final/ja/`
- 英語: `final/en/`
- サイズ: 2560 × 1600 px
- 形式: PNG、アルファチャンネルなし

画面内のTriggerは撮影時のユーザー設定をそのまま使用しています。見出しでは個別のキー割り当てを「デフォルト」と表現せず、QuickDrawのAction、Target、配送の仕組みを説明しています。

## 再生成

バンドルされたNode.jsと画像ライブラリを使い、`scripts/compose.mjs`を実行します。元画像は`raw/ja/`と`raw/en/`に保存されています。
