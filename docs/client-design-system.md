# Atelia Mac Client Design System

This document captures the durable UI rules implied by the current
`AteliaMacClient` implementation and the client sketch. Treat these rules as
product surface. They are intentionally concrete so future PRs can be reviewed
without re-litigating the visual direction.

## Design Intent

Atelia Mac is a dense, work-oriented client for supervising Secretary work,
project context, tool activity, and code changes. It should feel native,
quiet, precise, and operational. Avoid marketing-page composition, decorative
cards, oversized headings, saturated gradients, and playful illustration.

The default theme is light. The app currently forces `.preferredColorScheme(.light)`.
Dark mode requires a dedicated pass; do not ship partial dark styling.

## Typography

- Use bundled fonts through the shared helpers, not ad hoc system font stacks.
- Body, Japanese UI text, Latin labels, and file paths use `Font.atelia`.
  Code and diff output should use `JetBrainsMono-Regular` when those surfaces
  are rendered.
- Base content text is 14 pt. Top bar title is 14 pt medium. Section and row
  labels sit between 12.25 and 13.25 pt. Sidebar section headers use 14.25 pt.
- Sidebar row text uses `tracking(0.25)`. Do not apply negative letter spacing.
- Prefer regular and medium weights. Do not use bold as a substitute for
  hierarchy; hierarchy comes from placement, muted color, and compact spacing.
- Keep line lengths bounded: conversation content is 736 pt wide; user bubbles
  max at 566 pt with 13 pt horizontal and vertical padding.

## Material And Color

- The shell background is white with a 1 pt `clientSidebarRail` divider between
  sidebar and conversation.
- Sidebar background uses `NSVisualEffectView.Material.sidebar` with
  `.behindWindow`, then a white overlay at 0.80 opacity. Preserve this glassy but
  mostly-white appearance.
- Composer background uses `.contentBackground` with `.withinWindow`, white
  overlay at 0.94 opacity, 18 pt continuous corner radius, 1 pt
  `clientDockBorder`, and a very light shadow.
- Standard lines are `clientLine`, `clientLineSoft`, or `clientLineStrong`.
  Avoid custom one-off grays when an existing token fits.
- Status colors are semantic: `clientSuccess` for additions/success,
  `clientDanger` for removals/failure, `clientWarning` for permission risk or
  running state, `clientAccent` for Secretary identity, and `clientFileMention`
  for attached files.
- Do not introduce dominant purple, beige, dark slate, or gradient-heavy themes
  without an explicit design-system revision.

## Sidebar IA

- Sidebar width is fixed at 270 pt. Toolbar height is 48 pt; settings row height
  is 54 pt; navigational rows are 32 pt.
- The sidebar order is:
  1. Window/route toolbar.
  2. Primary navigation: `新しいスレッド`, `検索`.
  3. Global Secretary block.
  4. Project groups.
  5. Settings.
- Keep Global Secretary above project groups. It is cross-project scope, not a
  project item. It uses a globe glyph, the label `Global Secretary`, and the
  scope label `全プロジェクト`.
- Project groups use folder glyphs, optional short subtitles, and row-level
  counts or warnings. Group-local secondary rows belong under the localized
  `その他の設定` label with a subtle separator before that subsection.
- Use SF Symbols through `SidebarGlyph` for common actions. Keep glyphs
  monochrome, regular weight, and in the 12 to 14 pt range.
- Selected rows use `clientSidebarSelected` with 9 pt corner radius. Do not use
  high-contrast selection fills in the sidebar.

## Composer

- Composer width is 736 pt. Height is 112 pt normally and 193 pt with an
  attachment preview. The reserved footer stack is 190 pt.
- Composer corner radius is 18 pt. Keep it as the only docked input surface at
  the bottom of the conversation; do not nest it inside another card.
- Placeholder copy is action-oriented and contextual. The current composer
  keeps the active goal/scope visible above the placeholder and uses
  `@Global Secretary にフォローアップの変更を求める` when the input is empty.
- The left control is an extension affordance, not just a raw plus icon. Use
  `plus.circle` plus the label `拡張機能`, with a compact capsule, soft
  surface fill, and hairline border.
- Permission mode is visible in the footer and uses the shield warning icon plus
  warning color. Current risky mode copy is `フルアクセス`, but the displayed
  value must come from `ComposerConfiguration.permissionMode`.
- Model selection, microphone, and send controls stay on the right. Model copy
  must come from `ComposerConfiguration.selectedModel`; send uses a circular
  29 pt button, with near-black enabled state and muted gray disabled state.

## Conversation And Diff

- Current conversation content is centered in a 736 pt column. The implemented
  shell uses 24 pt top and bottom padding around the visible conversation stack.
  The top bar height is 52 pt with a soft bottom hairline.
- Current user messages align right, use `clientSurfaceSofter`, 8 pt radius,
  14 pt text, and max width 566 pt.
- Current Secretary activity is represented by an activity card with duration,
  title, checkmark bullets, and document/review preview pills.
- Intended follow-up: tool output should be rendered as a semantic block, not a
  screenshot. Show tool name, status, command, and output lines in
  `JetBrainsMono-Regular` 12 pt inside an 8 pt radius surface.
- Intended follow-up: change sets should be collapsed by default. The collapsed
  row should show title, two-line summary, total additions, total deletions, and
  file count.
- Intended follow-up: expanded change sets should use a scrollable diff area
  capped at 312 pt high. File headers should be 34 pt high. Diff headers should
  use mono 11 pt and 28 pt minimum height; diff lines should use mono 11 pt and
  22 pt minimum height.
- Intended follow-up: additions should use success text and success background
  at 0.08 opacity. Removals should use danger text and danger background at
  0.08 opacity. Context lines should stay on white.

## PR-Safe Implementation Rules

- Keep layout constants in Atelia client support tokens such as
  `AteliaClientLayout`, `AteliaClientDesign`, and `Color+AteliaClient`; do not
  scatter magic numbers across views. Any Codex App references are
  compatibility/reference material only and must not become Atelia API names.
- Preserve semantic models for conversation blocks. Current rendered blocks are
  message and activity; tool output and change set rendering remain follow-up
  surfaces. Rendering should follow the model, not parse strings to infer UI
  structure.
- Keep the mock client ready for dynamic data. Sidebar commands and items need
  stable IDs, project/resource IDs where applicable, surface metadata, and
  action metadata. Selection must derive from navigation item ID plus
  project/surface/resource IDs, not from display titles. Composer controls must
  read their labels, route keys, permission scopes, and selected model from
  model/config state rather than hard-coded display strings.
- New sidebar or composer behavior must update both this English document and
  the Japanese counterpart in the same PR.
- New surface tokens should be added only when an existing token cannot express
  the state. Name tokens by role, not by raw color.
- Do not make unrelated product or IA changes in visual PRs. If a design change
  requires a contract, accessibility, or package-surface decision, split it or
  document the follow-up issue.
- Validate PRs with `swift build` when code changes, `git diff --check` always,
  and a visual review for sidebar, composer, and conversation states when UI
  changes are present. Include expanded diff state in visual review once that
  surface is implemented.
