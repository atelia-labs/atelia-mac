# Atelia Mac Client Design System

この文書は、現在の `AteliaMacClient` 実装と `client sketch` から読み取れる
永続的な `UI` ルールを固定するものです。見た目は `product surface` です。
将来の PR で毎回方向性を議論し直さないよう、レビュー可能な粒度まで具体化します。

## Design Intent

Atelia Mac は、`Secretary` の作業、`project context`、`tool activity`、`code change`
を監督するための高密度な業務 `client` です。`native`、静か、精密、運用向きに見える
必要があります。`marketing page` 的な構成、装飾 `card`、巨大な `heading`、強い
`gradient`、遊びの強い `illustration` は避けます。

既定 `theme` は `light` です。現在の `app` は `.preferredColorScheme(.light)` を指定
しています。`dark mode` は専用の設計 `pass` が必要です。部分的な `dark styling` を
混ぜてはいけません。

## Typography

- `Font` は shared helper を使います。場当たり的な `system font stack` を各 `view` に
  書かないでください。
- Body、日本語 `UI` `text`、`general prose` は `Font.atelia` を使います。Latin `label` と
  `file path` は `Font.ateliaLatin` を優先します。Current `semantic text surface` では、
  `mixed copy` や `legacy sidebar label` が残る箇所で `Font.atelia` を使う場合があります。
  visible な `Global Secretary` sidebar `label` は現在の `transition exception` です。
  これらの body / Latin helper は、bundled `text font` が明示的に `wire` されるまでは
  `system-font fallback` に乗る `semantic wrapper` です。`Code` と `diff output` は mono
  helper を使い、その surface を render する時点で bundled `JetBrainsMono-Regular`
  を target します。
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
- 現在の project-secondary IA は、その subsection の下に
  `拡張機能` と `オートメーション` の placeholder row を含みます。
  `プロジェクト設定` は active であり、placeholder row ではありません。
- Common action は `SidebarGlyph` 経由の SF Symbols を使います。Glyph は
  monochrome、regular weight、12 から 14 pt の範囲に収めます。
- Selected row は `clientSidebarSelected` と 9 pt corner radius を使います。
  Sidebar selection に高 contrast な fill を使わないでください。

## Project Add Flow

- project section の add menu は hover 時のみ表示します。section header に
  hover したときだけ folder-with-badge-plus の trigger と 2 つの menu item、
  `新規フォルダを作成` と `既存のフォルダを使用` を出してください。
- menu item は custom modal chrome ではなく native panel を開きます。
  `新規フォルダを作成` は `NSSavePanel` を使い、title は
  `新規フォルダを作成`、message は `Atelia で使うフォルダ名と保存先を指定してください。`、
  prompt は `作成` です。`既存のフォルダを使用` は `NSOpenPanel` を使い、
  title は `既存のフォルダを使用`、message は
  `Atelia で使うフォルダを選択してください。`、prompt は `選択` です。
- フォルダが確定したら即座に `LocalProjectRegistration` として永続化し、
  normal project group として sidebar に表示します。選択された folder name を
  group title にし、registration subtitle を使ってください。別の `追加候補`
  candidate row や pending dismiss slot は表示しません。
- folder の confirm では registered project group を選択して開きます。
  panel の cancel は sidebar を変えません。選択された folder が現在の project
  status snapshot と一致する場合は、local registration を重複作成せず、
  既存の project group を選択します。

## Composer

- Composer width は 736 pt。通常 height は 112 pt、attachment preview がある場合は
  193 pt です。現在の footer control row は 42 pt high です。
  `composerFooterHeight` token は sketch / future spacing 用の reserve であり、
  current implementation layout として扱ってはいけません。
- Composer corner radius は 18 pt。Conversation 下部に dock された唯一の input
  surface として扱い、別 card の中に nest しないでください。
- Placeholder copy は行動を促す contextual copy にします。現在の composer は
  active goal/scope を placeholder の上に表示し、空入力時は
  `@Global Secretary にフォローアップの変更を求める` を使います。
- 左端 control は file attachment affordance です。`paperclip` と
  `ファイル` label を使い、compact capsule、soft surface fill、hairline border を
  持たせます。
- Permission mode は footer 上で見える状態にし、shield warning icon と warning
  color を使います。現在の risky mode copy は `フルアクセス` ですが、表示値は
  `ComposerConfiguration.permissionMode` から取得します。
- Model selection、microphone、send control は右側に置きます。Model copy は
  `ComposerConfiguration.selectedModel` から取得します。Send は 29 pt の circular
  button です。Enabled は near-black、disabled は muted gray です。

## Conversation And Diff

- Current conversation content は 736 pt column に置きます。実装済み shell は、
  表示される conversation stack の上に 34 pt、下に 28 pt padding を使います。Top
  bar height は 52 pt、bottom に soft hairline を置きます。
- Current user message は右寄せ、`clientSurfaceSofter`、12 pt radius、14 pt text、
  最大 width 566 pt です。
- Current Secretary activity は、Secretary mark、status、duration、title、小さな
  success-dot bullet を持つ unframed inline activity block として表示します。
  Document/review preview pill は current rendering ではなく intended follow-up
  です。
- Current mock shell は tool output を screenshot ではなく semantic block として
  表示します。Tool name、status、command、output lines を表示し、8 pt radius
  surface 内に mono 12 pt で置きます。
- Current mock shell は change set を collapsed default で表示します。Collapsed row
  には title、2 line summary、total additions、total deletions、file count を表示
  します。
- Current mock shell の expanded change set は fixed 312 pt scroll viewport を
  使います。File header は 34 pt。Diff header は mono 11 pt、min height 28 pt。
  Diff line は mono 11 pt、min height 22 pt です。
- Current mock shell の addition marker は success semantic color、removal marker
  は danger semantic color を使います。Addition/removal line background はそれぞれ
  の semantic color を 0.08 opacity で使い、diff content text は `clientText` の
  ままにします。Context line は white のままにします。

## PR-Safe Implementation Rules

- Layout constant は `AteliaClientLayout`、`AteliaClientDesign`、
  `Color+AteliaClient` などの Atelia client support token に置きます。View 内に
  magic number を散らさないでください。Codex App reference は compatibility /
  reference material に限り、Atelia API 名として固定してはいけません。
- Conversation block の semantic model を保ちます。現在 render される block は
  message、activity、tool output、change set で、`AteliaConversationModels` に
  backed されています。Production data wiring と production-side behavior は
  follow-up work です。Rendering は model に従い、文字列 parse で UI structure を
  推測しないでください。
- Dynamic data に置き換えられる状態を維持します。Sidebar command / item は stable
  ID、必要な project/resource ID、surface metadata、action metadata を持ちます。
  Selection は display title ではなく、navigation item ID と
  project/surface/resource ID から導出します。現在の composer wiring は permission
  mode の display と accessibility scope、selected model の display と route key を
  config-backed にしています。Extension affordance label と empty placeholder copy は
  まだ hard-coded mock string です。これらを model/config state に移すことは
  follow-up model work とします。
- Sidebar または composer の behavior を増やす PR では、この英語 document と日本語
  document の両方を同じ PR で更新してください。
- 新しい surface token は既存 token で状態を表現できない場合だけ追加します。Token
  名は raw color ではなく role で付けます。
- Visual PR で無関係な product/IA change を混ぜないでください。Design change が
  contract、accessibility、package-surface decision を必要とする場合は、PR を分ける
  か follow-up issue を明記します。
- Code change がある場合は `swift build`、常に `git diff --check` を実行します。
  UI change がある場合は sidebar、composer、conversation state を visual review
  してください。Conversation visual review では collapsed diff state と expanded
  diff state の両方を対象にします。
