# Atelia Mac Client Design System

この文書は、現在の `AteliaMacClient` 実装と client sketch から読み取れる
永続的な UI ルールを固定するものです。見た目は product surface です。
将来の PR で毎回方向性を議論し直さないよう、レビュー可能な粒度まで具体化します。

## Design Intent

Atelia Mac は、Secretary の作業、project context、tool activity、code change
を監督するための高密度な業務 client です。native、静か、精密、運用向きに見える
必要があります。marketing page 的な構成、装飾 card、巨大な heading、強い
gradient、遊びの強い illustration は避けます。

既定 theme は light です。現在の app は `.preferredColorScheme(.light)` を指定
しています。dark mode は専用の設計 pass が必要です。部分的な dark styling を
混ぜてはいけません。

## Typography

- Font は bundled font と shared helper を使います。場当たり的な system font stack
  を各 view に書かないでください。
- Body、日本語 UI text、Latin label、file path は `Font.atelia` を使います。
  Code と diff output は、その surface を render する時点で
  `JetBrainsMono-Regular` を使います。
- Base content text は 14 pt。Top bar product title は 16 pt semibold です。
  Section と row label は 12.25 から 13.25 pt。Sidebar section header は
  14.25 pt です。
- Sidebar row text は `tracking(0.25)` を使います。negative letter spacing は
  使いません。
- Weight は regular と medium を基本にします。bold で階層を作らず、配置、muted
  color、compact spacing で階層を作ります。
- 行幅は必ず制御します。Conversation content は 736 pt、user bubble は最大
  566 pt、horizontal/vertical padding は 13 pt です。

## Material And Color

- Shell background は white。Sidebar と conversation の間に 1 pt の
  `clientSidebarRail` divider を置きます。
- Sidebar background は `NSVisualEffectView.Material.sidebar` と `.behindWindow` を
  使い、white overlay 0.80 を重ねます。glassy だがほぼ white の見え方を維持します。
- Composer background は `.contentBackground` と `.withinWindow`、white overlay
  0.94、18 pt continuous corner radius、1 pt `clientDockBorder`、ごく弱い shadow
  を使います。
- 線は `clientLine`、`clientLineSoft`、`clientLineStrong` を使います。既存 token で
  表現できる場合、one-off の gray を増やさないでください。
- Status color は意味で使い分けます。addition/success は `clientSuccess`、
  removal/failure は `clientDanger`、permission risk/running は `clientWarning`、
  Secretary identity は `clientAccent`、attached file は `clientFileMention` です。
- 明示的な design-system revision なしに、purple、beige、dark slate、gradient に
  支配された theme を導入しないでください。

## Sidebar IA

- Sidebar width は 270 pt 固定です。Toolbar は 48 pt、settings row は 54 pt、
  navigation row は 32 pt です。
- Sidebar order は次の通りです。
  1. Window/route toolbar。
  2. Primary navigation: `新しいスレッド`、`検索`。
  3. Global Secretary block。
  4. Project groups。
  5. Settings。
- Global Secretary は project group より上に置きます。これは cross-project scope で
  あり、project item ではありません。globe glyph、`Global Secretary` label、
  `全プロジェクト` scope label を使います。
- Project group は folder glyph、短い optional subtitle、row-level count または
  warning を持ちます。Group-local secondary row は localized label である
  `その他の設定` の下に置き、その subsection の前に subtle separator を入れます。
- Common action は `SidebarGlyph` 経由の SF Symbols を使います。Glyph は
  monochrome、regular weight、12 から 14 pt の範囲に収めます。
- Selected row は `clientSidebarSelected` と 9 pt corner radius を使います。
  Sidebar selection に高 contrast な fill を使わないでください。

## Composer

- Composer width は 736 pt。通常 height は 112 pt、attachment preview ありでは
  193 pt です。Reserved footer stack は 190 pt です。
- Composer corner radius は 18 pt。Conversation 下部に dock された唯一の input
  surface として扱い、別 card の中に nest しないでください。
- Placeholder copy は行動を促す contextual copy にします。現在の composer は
  active goal/scope を placeholder の上に表示し、空入力時は
  `@Global Secretary にフォローアップの変更を求める` を使います。
- 左端 control は raw plus icon ではなく extension affordance です。`plus.circle` と
  `拡張機能` label を使い、compact capsule、soft surface fill、hairline border を
  持たせます。
- Permission mode は footer 上で見える状態にし、shield warning icon と warning
  color を使います。現在の risky mode copy は `フルアクセス` ですが、表示値は
  `ComposerConfiguration.permissionMode` から取得します。
- Model selection、microphone、send control は右側に置きます。Model copy は
  `ComposerConfiguration.selectedModel` から取得します。Send は 29 pt の circular
  button です。Enabled は near-black、disabled は muted gray です。

## Conversation And Diff

- Current conversation content は 736 pt column に置きます。実装済み shell は、
  表示される conversation stack の上下に 24 pt padding を使います。Top bar height
  は 52 pt、bottom に soft hairline を置きます。
- Current user message は右寄せ、`clientSurfaceSofter`、8 pt radius、14 pt text、
  最大 width 566 pt です。
- Current Secretary activity は、duration、title、checkmark bullet、document/review
  preview pill を持つ activity card として表示します。
- Intended follow-up: tool output は screenshot ではなく semantic block として表示
  します。Tool name、status、command、output lines を表示し、8 pt radius surface
  内に `JetBrainsMono-Regular` 12 pt で置きます。
- Intended follow-up: change set は collapsed default にします。Collapsed row には
  title、2 line summary、total additions、total deletions、file count を表示します。
- Intended follow-up: expanded change set は scrollable diff area を使い、高さは
  312 pt 上限にします。File header は 34 pt。Diff header は mono 11 pt、min height
  28 pt。Diff line は mono 11 pt、min height 22 pt です。
- Intended follow-up: addition は success text と success background 0.08 opacity。
  Removal は danger text と danger background 0.08 opacity。Context line は white
  のままにします。

## PR-Safe Implementation Rules

- Layout constant は `AteliaClientLayout`、`AteliaClientDesign`、
  `Color+AteliaClient` などの Atelia client support token に置きます。View 内に
  magic number を散らさないでください。Codex App reference は compatibility /
  reference material に限り、Atelia API 名として固定してはいけません。
- Conversation block の semantic model を保ちます。現在 render される block は
  message と activity です。Tool output と change set rendering は follow-up
  surface です。Rendering は model に従い、文字列 parse で UI structure を推測
  しないでください。
- Dynamic data に置き換えられる状態を維持します。Sidebar command / item は stable
  ID、必要な project/resource ID、surface metadata、action metadata を持ちます。
  Selection は display title ではなく、navigation item ID と
  project/surface/resource ID から導出します。Composer control の label、route key、
  permission scope、selected model は hard-code ではなく model/config state から
  表示します。
- Sidebar または composer の behavior を増やす PR では、この英語 document と日本語
  document の両方を同じ PR で更新してください。
- 新しい surface token は既存 token で状態を表現できない場合だけ追加します。Token
  名は raw color ではなく role で付けます。
- Visual PR で無関係な product/IA change を混ぜないでください。Design change が
  contract、accessibility、package-surface decision を必要とする場合は、PR を分ける
  か follow-up issue を明記します。
- Code change がある場合は `swift build`、常に `git diff --check` を実行します。
  UI change がある場合は sidebar、composer、conversation state を visual review
  してください。Expanded diff state は、その surface が実装された後に visual review
  対象へ含めます。
