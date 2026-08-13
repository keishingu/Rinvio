# ADR-0002: AI支援でUser Application Packを生成し、検証後に取り込む

- Status: Proposed
- Date: 2026-08-14
- Scope: User-defined Application / AI-assisted import / Action Catalog / shortcut mapping

## Context

QuickDrawのBuilt-in Catalogは、対応Applicationのidentityと、Built-in ActionをそのApplicationで実行するShortcutを持つ。現状はApplicationが`ActionTarget` enum、表示情報がSwiftの固定配列、Mappingがbundled JSONに固定されているため、ユーザーは未対応Applicationを追加できない。

任意のApplicationを追加可能にする場合でも、ユーザー自身に内部JSON、virtual key code、domain、Routing構造を理解してもらうべきではない。一方、QuickDrawへLLM API、API key、特定AIベンダーへの依存を組み込み、AIの回答を直接実行することも避けたい。

例えばBearを追加する場合、JSON SchemaだけではAIは次を判断できない。

- BearがNotes系Applicationであること
- QuickDrawがNotesカテゴリーを知っているか
- `notes.newNote`と「新しいWindowを開く」が同じ意味ではないこと
- Notesカテゴリーで利用可能なBuilt-in Actionが何か

このため、AIには出力形式だけでなく、QuickDrawが理解するカテゴリーとActionの意味を、型定義に相当するCatalogとして渡す必要がある。

## Decision

### 1. AIを内蔵せず、AI向け指示の生成と回答のimportを提供する

QuickDrawはLLMを呼び出さない。ユーザーが任意のAIを利用できるよう、選択したApplicationに合わせた指示を生成する。

```text
Applicationを選択
  → QuickDrawがAI向け指示をコピー
  → ユーザーが任意のAIへ渡す
  → AIがApplication Pack JSONを返す
  → QuickDrawへ貼り付ける
  → validationとpreview
  → disabled状態で追加
  → user test後にenable
```

QuickDrawはAIの回答を信頼せず、外部から受け取る未信頼データとして扱う。

### 2. 初期scopeは「既知のAction体系に適合するnative Application」とする

初期versionで追加できるものを次に限定する。

- インストール済みのnative macOS Application
- QuickDrawに定義済みのカテゴリーとBuilt-in Action
- Foreground Applicationへの単一keyboard shortcut配送
- Mappingごとの出典URL

次は扱わない。

- User-defined Actionまたはカテゴリーの即時作成
- AppleScript、shell、JavaScript、任意コード
- 複数step、chord、macro、workflow
- Accessibility element、menu item、画面座標
- Web Application
- AIが指定する任意のexecution method

これはdynamic plugin systemではなく、実行能力を持たないdata-onlyの`User Application Pack`である。

### 3. AIにはJSON SchemaとAction Catalogを一緒に渡す

QuickDrawが生成する指示は、少なくとも次を含む。

1. 選択したApplicationのdisplay name、bundle identifier、version、macOSであること
2. Application Pack JSON Schema
3. QuickDraw Action Catalog
4. 公式資料を優先し、不明なMappingを推測しない規則
5. 単一shortcut以外を含めない規則
6. JSON以外を返さない規則

Action Catalogはカテゴリーごとに、AIが意味を比較できる情報を持つ。

```json
{
  "catalogVersion": 1,
  "categories": [
    {
      "id": "notes",
      "name": "Notes",
      "description": "ノートの作成、編集、検索、整理を主目的とするApplication",
      "includes": ["personal notes", "knowledge base", "markdown notes"],
      "excludes": ["source code editor", "word processor"],
      "actions": [
        {
          "id": "notes.newNote",
          "name": "New Note",
          "description": "新しい空のノートを作成する",
          "excludes": [
            "新しいWindowを開くだけの操作",
            "template選択画面を開くだけの操作"
          ],
          "safety": "normal",
          "allowedExecutionMethods": ["keyboardShortcut"]
        },
        {
          "id": "notes.search",
          "name": "Search Notes",
          "description": "Application内の全ノートを対象に検索を開始する",
          "excludes": ["現在のノート本文だけを検索する操作"],
          "safety": "normal",
          "allowedExecutionMethods": ["keyboardShortcut"]
        }
      ]
    }
  ]
}
```

カテゴリーとActionのIDだけでなく、`description`と`excludes`を渡す。名前が似ているがsemanticに異なる操作を誤ってMappingする可能性を下げるためである。

### 4. カテゴリー判定はAIの候補であり、QuickDrawの推測結果ではない

AIはAction Catalogの既知カテゴリーから候補を選び、理由を返す。QuickDrawはそのカテゴリーIDがCatalogに存在することを検証し、追加前にユーザーへ確認する。

Bearの回答例:

```json
{
  "schemaVersion": 1,
  "type": "quickdraw.application-mapping",
  "basedOnCatalogVersion": 1,
  "application": {
    "displayName": "Bear",
    "bundleIdentifier": "net.shinyfrog.bear",
    "version": "2.4"
  },
  "classification": {
    "categoryID": "notes",
    "reason": "ノートの作成、編集、検索を主目的とするApplicationであるため"
  },
  "mappings": [
    {
      "actionID": "notes.newNote",
      "shortcut": {
        "key": "n",
        "modifiers": ["command"]
      },
      "sourceURL": "https://bear.app/faq/shortcuts/"
    }
  ]
}
```

QuickDrawは`categoryID`からdomainを推測しない。既知の`actionID`をAction Catalogで引き、そのActionが属するカテゴリーを正本とする。Applicationが属する実行scopeは、検証済みMappingに含まれるActionのカテゴリー集合から導出する。

```text
notes.newNote      → notes
notes.search       → notes
chat.quickSwitcher → chat
```

AIが`classification.categoryID = notes`としながら`development.runProject`を返した場合は、カテゴリー不整合として拒否する。

### 5. 未知カテゴリーは実行可能な型として自動追加しない

QuickDrawにNotesカテゴリーやNotes Actionがまだ存在しない場合、AIがBearをNotes Applicationと正しく分類しても、その回答から`notes`や`notes.newNote`を自動作成しない。

未知カテゴリーは、実行定義とは分離したsuggestionとして表示できる。

```json
{
  "unsupportedCategorySuggestion": {
    "name": "Notes",
    "reason": "QuickDraw Action Catalogに適合するカテゴリーがない"
  }
}
```

UIでは「BearはNotes Applicationの候補ですが、現在QuickDrawにはNotes Actionがありません」と表示する。カテゴリー／Action体系そのものの拡張は、通常のApplication importとは別の設計判断とする。

### 6. AI回答用Schemaを内部Catalog Schemaより狭くする

AIに生成させるのは、Application識別情報、既知Action ID、human-readableなshortcut、出典だけとする。

AIに生成させない値:

- QuickDraw内部のApplication ID
- domainまたは実行scope
- iconまたはSF Symbol
- virtual key code
- shortcutのdisplay value
- enabled状態
- confidenceまたはverified状態
- arbitrary execution method

QuickDrawは`key`と`modifiers`からkeyboard layoutを考慮して内部`KeyStroke`を生成する。AIが返した「confirmed」等の自己評価は採用せず、import直後は常に`AI generated / unverified`とする。

### 7. validation、preview、testを通過してからenableする

#### 拒否する入力

- 未対応のschema versionまたはcatalog version
- 選択したApplicationと異なるbundle identifier
- Built-in Applicationと衝突するbundle identifier
- 未知のcategory IDまたはAction ID
- Actionとcategoryの不整合
- 同一Actionの重複Mapping
- 不正なkeyまたはmodifier
- chord、macro、script、未知のexecution method
- SystemまたはFinder ActionへのUser Mapping
- sizeまたはMapping数の上限超過

#### 警告する入力

- source URLがHTTPSではない
- Application versionが生成対象versionと異なる
- 同一出力shortcutを複数Actionが共有する
- 追加により既存Triggerのscope conflictが増える
- 特殊keyまたはkeyboard layout依存

追加前にはJSONではなく、意味を読めるpreviewを表示する。

| Action | QuickDraw Trigger | Applicationへ送るShortcut | Source | Verification |
|---|---:|---:|---|---|
| New Note | Suggested Trigger | `⌘N` | 公式資料を開く | Unverified |
| Search Notes | Suggested Trigger | `⌘⌥F` | 公式資料を開く | Unverified |

追加直後はApplicationをdisabledにする。ApplicationをForegroundにしたMappingごとのtestを提供し、ユーザーが結果を確認してからenableする。

### 8. Built-inとUser Packを合成したCatalog SnapshotをRoutingの正本にする

現在の`ActionTarget` enumは、dynamicなUser Applicationを表現できないため、文字列値を持つ`ApplicationID`へ移行する。Built-in IDはstatic constantとしてAPIの利便性を維持し、User ApplicationにはQuickDrawが`user.application.<UUID>`を割り当てる。

```text
BuiltInCatalogSource
        +
UserApplicationPackStore
        ↓
MergedCatalogSnapshot
        ↓
Configuration / Router / UI
```

Built-in definitionを優先し、User Packから上書きできないようにする。RoutingはMerged Catalog Snapshotだけを参照する。

```text
Foreground bundle identifier
  → ApplicationID
  → Action scope compatibility
  → User shortcut override
  → Application Pack default shortcut
  → Built-in default shortcut
  → delivery
```

### 9. User PackとConfiguration Overrideを別に保存する

```text
~/Library/Application Support/QuickDraw/
├── configuration.json
└── ApplicationPacks/
    └── <UUID>.json
```

- `configuration.json`: Trigger、shortcut override、enabled状態
- `ApplicationPacks`: Application identity、classification、default Mapping、source、verification metadata

Packの更新や削除と、ユーザーが行ったMapping Overrideを分離する。Packを削除する時は関連Overrideの扱いを確認し、暗黙に別Applicationへ再利用しない。

## User experience

Applications画面に`Applicationを追加…`を設ける。

1. インストール済みの未対応Applicationを選択する。
2. QuickDrawがname、bundle identifier、version、iconをローカルから取得する。
3. `AI向け指示をコピー`を押す。
4. 任意のAIへ貼り付ける。
5. `AIの回答を貼り付け`へJSONを入力する。
6. QuickDrawがvalidation結果、カテゴリー候補、Mappingをpreviewする。
7. ユーザーがカテゴリーとMappingを確認して追加する。
8. ApplicationをForegroundにしてMappingをtestする。
9. `QuickDrawの対象`をONにする。

AIがMarkdown code fenceで単一のJSONを囲んだ場合のみ、fenceを除去して受理してよい。説明文からJSONらしい部分を曖昧に抽出しない。

## Consequences

### Positive

- ユーザーは内部JSONやkey codeを理解せずApplicationを追加できる。
- AI provider、API key、network、model versionへQuickDrawが依存しない。
- AIは公式資料の調査と構造化に使い、実行可否はQuickDrawが決められる。
- Actionのsemantic boundaryを保ち、似ているだけの操作への誤Mappingを減らせる。
- downloaded executableやarbitrary scriptを導入せず、既存の安全境界を維持できる。

### Negative

- 真に未知のカテゴリーをその場で追加することはできない。
- Action Catalogのdescriptionとexclusionを継続的に整備する必要がある。
- `ActionTarget` enum、固定Application表示、Configuration schemaのmigrationが必要になる。
- AI回答の品質により、ユーザーが修正または再生成する場合がある。
- 公式Shortcut自体がApplication versionやユーザー設定で変わる可能性は残る。

## Phased delivery

1. `ApplicationID`とMerged Catalog Snapshotを導入する。
2. Action CatalogにAI向けsemantic metadataを追加する。
3. User Application Pack Schema、Validator、Storeを追加する。
4. Applications画面をCatalog-drivenにする。
5. Application選択、prompt copy、response paste、previewを追加する。
6. Mapping testとverification stateを追加する。
7. 利用実績を踏まえ、Web ApplicationまたはUser-defined Actionを別ADRで検討する。

## Alternatives considered

### JSON editorを直接提供する

実装は小さいが、ユーザーへQuickDraw内部構造の理解を要求し、key codeやdomainの誤入力を招くため採用しない。

### QuickDrawがLLM APIを直接呼ぶ

一体化したUXにはなるが、API key、課金、privacy、provider dependency、network failure、model更新をQuickDrawが所有することになる。初期設計では採用しない。

### AIにカテゴリー、Action、execution methodを自由生成させる

未知Applicationへの対応範囲は広いが、Actionの意味、Trigger conflict scope、実行能力、安全性を外部の非決定的出力へ委ねることになるため採用しない。

### AIのカテゴリー判定を使わず、ユーザーに先に選ばせる

安全で単純だが、カテゴリー名を理解していないユーザーに判断を要求する。AI候補をpreviewで確認する方式を採用し、必要ならユーザーが既知カテゴリーへ変更できるようにする。

## Open questions

- 初期releaseまでにNotes等の新しいカテゴリーをどこまでBuilt-in Action Catalogへ追加するか。
- Application Packのexport/importとcommunity sharingを提供するか。
- source URLのdomain allowlistまたは署名済みPackを将来導入するか。
- Mapping test結果をApplication versionごとに失効させるか。
- keyboard layout間で`key`をどう正規化し、physical keyとcharacter semanticsのどちらを保存するか。

## References

- [QuickDrawプロダクト・技術設計書](../quickdraw-product-design.ja.md)
- [ショートカット設計原則](../shortcut-design-principles.ja.md)
- [ADR-0001: Browser ExtensionをQuickDrawのAdapterとして同一リポジトリで管理する](0001-browser-extension-adapter-and-monorepo.md)
