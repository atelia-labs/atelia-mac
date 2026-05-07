# Standard Surfaces

Atelia Mac は、固定されたアプリ本体にいくつかの extension slot を後付けするものではありません。Atelia Mac は、Surface Protocol Resolver を内包する native shell です。Atelia に同梱される surface を含むすべての user-facing surface は、package declaration によって登録され、その resolver によって解釈されなければなりません。

したがって、default UI は透明な distribution privilege を持ちます。baseline operation に必要な host-required criticality、必要な場合の non-removability、host policy に記録される app binary provenance です。ただし hidden execution authority は持たず、他のすべての package と同じ protocol、component catalog、action routing、context graph、permission model を使います。

## Glossary

- **Shell**: native macOS application container。window、platform integration、accessibility、secure storage、Surface Protocol Resolver を所有します。shell 自体は surface ではありません。
- **Surface Protocol Resolver**: package manifest、surface declaration、context participation、action routing、lifecycle、trust、presentation を解釈する host-side resolver です。structured declaration を解釈するものであり、downloaded code execution runtime ではありません。
- **Package**: 1つ以上の surface、capability、schema、action、resource、permission を宣言する distribution unit です。
- **Built-in package**: app binary に同梱される package です。built-in は distribution fact であり、別の protocol model ではありません。
- **Extension package**: registry、repository、user-selected source から install される package です。built-in package と同じ surface protocol を使います。
- **Surface**: project space 内に mount される protocol participant です。surface は package に属し、lifecycle を持ち、context を読んだり contribute したりでき、action を propose し、presentation を宣言します。
- **Presentation**: surface の semantic display layer です。presentation declaration は、validated data を host-provided component でどう render するかを表します。arbitrary client UI code ではありません。
- **Context graph**: user、project Secretary、eligible surfaces が共有する、structured で permission-aware な project state です。
- **Action**: resolver によって policy、permission、approval、audit、Secretary / service broker へ route される declared proposal です。
- **Activation context**: prompt、approval、recovery、task flow のために resolver が mounted surface に付与する session data です。surface は自分で activation context を作れません。
- **Trust level**: platform signing、bundle membership、registry verification、user install choice から resolver が導出する package provenance です。
- **Host policy**: host binary と一緒に配布される resolver-readable policy です。criticality eligibility、trust threshold、default package enablement、default permission grant、platform-specific divergence record を定義します。host policy は host release と一緒に versioning されます。

## Specification Home

この文書は Atelia Mac の Surface Protocol architecture を定義します。normative な Surface Protocol specification は AEP specification family の [Surface Protocol](../../atelia/docs/surface-protocol.ja.md) に置きます。詳細な declaration schema、attachment point semantics、field binding、lifecycle state machine、context subscription、action routing、trust derivation は、そこで定義するか、その文書が参照する文書で定義しなければなりません。

## Protocol Layers

AEP Presentation は、より広い Surface Protocol の一層です。surface model から独立した別システムにしてはいけません。

Surface Protocol は次を含みます。

- **Declaration**: package manifest、surface id、capability、schema、permission、resource、compatibility。
- **Lifecycle**: mount、activate、suspend、destroy、degrade、recover。
- **Context**: subscribe、contribute、retract、provenance、visibility、scope。
- **Action**: propose、route、confirm、approve、broker 経由の execute、audit、result report。
- **Presentation**: validated data に bind された host-rendered semantic component。
- **Trust**: provenance、trust level、criticality、allowed activation context、authority limit。

これは structured declaration と brokered action のための protocol です。client code を download / execute する仕組みとして説明してはいけません。

具体的な declaration format は Surface Protocol specification で定義します。最初の実装では、resolver が package を mount する前に parse できる schema-validated format を使わなければなりません。

## Normative Language

この文書では、shell、resolver、host policy、package validation が enforce する architectural invariant に **must** を使います。許可される capability には **may** を使い、正当な将来例外があり得る product guidance に限って **should** を使います。

## Principle

Atelia のすべての user-facing surface は同じ Surface Protocol を使わなければなりません。built-in package と extension package の違いは distribution と trust level であり、private UI architecture ではありません。

- presentation は semantic で host-rendered である。
- state は provenance 付きで shared project context graph に入る。
- action は同じ permission、approval、audit path を通る。
- lifecycle と degradation は protocol state である。
- built-in package は、明示された trust rule と activation context 以外の hidden execution authority を持たない。

## なぜ重要か

Atelia は、ユーザーの作業空間であり生活空間になることを目指します。documents、browser、calendar、tasks、notes、media、GitHub、terminal、reviews、automations、将来の tools は、ひとつの coherent client の中に現れる必要があります。ただしそれらの capability は package-provided surface であり、initial client に build-in される前提ではありません。

この広さは、ひとつの hard-coded navigation hierarchy や universal screen layout では支えられません。一方で、すべての package に arbitrary pixels と arbitrary behavior を許すことでも支えられません。client には protocol-level の中間地帯が必要です。多様な仕事に対応できる柔軟性を持ちつつ、理解可能で、native で、inspectable で、安全であることが必要です。

Atelia の中で package-provided な surface、resource、activity が開かれているとき、ユーザーと project Secretary は同じ context を共有できます。この shared context が product value です。UI architecture は、世界を privileged default app と secondary extension panels に分断するのではなく、この価値を保存しなければなりません。

## Shell

Shell は native app container です。surface ではなく、product UI を直接所有しません。shell は次を提供します。

- windows、native platform behavior、accessibility。
- secure local storage と platform permission bridges。
- Surface Protocol Resolver。
- built-in package registry resolution。
- native component catalog implementation。
- package resolution が失敗したときの safe mode entry。

Shell は code signing や app bundle membership のような避けられない platform fact を、trust assertion として resolver に公開できます。その assertion は protocol model に入る data であり、hidden UI authority ではありません。

client baseline は product-specific surface を所有しません。ただし package が一級の体験を作るために必要な shared primitives、native component catalog、platform permission bridge、context contract、action contract、brokered service boundary は提供してよいです。

## Surfaces And Packages

Surface は Surface Protocol Resolver によって project space 内に host されます。surface は built-in package から来る場合も extension package から来る場合もあります。initial built-in package set は意図的に小さくします。

- project home。
- project conversation。
- project selection and onboarding。
- extension installation、inspection、disabling、rollback、safe mode。
- settings。
- permission、approval、audit、recovery surfaces。

built-in set は厳しい条件を満たさなければなりません。fresh install 後に Atelia が usable state に到達するため不可欠な surface、または resolver が保証しなければならない trust、permission、recovery、package safety decision を媒介する surface だけが built-in に属します。user が bundled official package を enable することで合理的に得られる surface は、built-in client core にしてはいけません。

documents、browser、tasks、calendar、notes、media、GitHub、review、terminal などの product area は、bundled official package または third-party extension package として提供されます。install された後は native で中心的に感じられてよいですが、minimal client baseline には含めません。architectural point は、それらを package model で配布することであり、product から不在にすることではありません。

## Surface Lifecycle

すべての surface は resolver によって lifecycle 管理されます。

- **available**: installed package によって宣言され、host と compatible である。
- **mounted**: project space または host slot に配置されている。
- **active**: visible、または focus / activation context を受け取っている。
- **suspended**: preserved されているが active ではない。
- **degraded**: fallback presentation または reduced capability で mounted されている。
- **destroyed**: current project space から removed されている。

Surface は criticality を宣言します。

- **host-required**: baseline operation に必要。project conversation、permission prompts、approvals、audit visibility、recovery など。`host-shipped built-in` package だけがこの tier を claim できます。
- **user-removable**: user が明示的に disable できる bundled / installed surface。
- **optional**: enabled または requested されたときだけ現れる surface。

Criticality は self-authorized ではありません。resolver は package trust level と host policy に基づいて、claimed criticality tier を受け入れるか downgrade します。

## Trust Model

Trust は package provenance から導出され、surface 自身の claim からは導出されません。

Package distribution と criticality は別の軸です。

| Package class | Distribution | Default criticality |
| --- | --- | --- |
| `host-shipped built-in` | app binary に同梱され、platform code signing に紐付く | baseline operation に必要な場合のみ `host-required` を claim できる |
| `bundled official` | Atelia が配布し、default installed または setup 時に recommended される | 通常は `user-removable`。明示的な host policy が baseline requirement を記録する場合のみ non-removable になり得る |
| `verified third-party` | trusted registry で automated validation、signature、compatibility metadata を持って配布される | `user-removable` または `optional` |
| `unverified third-party` | user が external source から明示的に install する | `optional`。user policy は enable できるが、`host-required` にはできない |

これらの class は distribution path であり、別々の UI architecture ではありません。resolver は、同じ platform 上の third-party package が構造的に利用できない capability を built-in package や bundled official package に付与してはいけません。例外は host policy に platform limitation として記録しなければなりません。

Criticality は lifecycle claim であり、distribution class ではありません。Distribution は claim を eligible にできますが、resolver はそれでも host policy に照らして validate します。

Distribution trust は、package がどのように bundle、sign、update、review、initially enable されるかに影響します。しかし use-time permission check、action routing、audit logging、degradation、inspection、context provenance を bypass するものではありません。platform constraint によって third-party package が built-in package や bundled official package と同じ扱いを受けられない場合、host policy はそれを trust preference ではなく platform limitation として記録しなければなりません。official package は trusted default であり得ますが、hidden client core にはなりません。

## Default Experience

Protocol-first は blank canvas や configuration-first を意味しません。default は coherent project space を提供しなければなりません。

- project を選ぶと project workspace が開く。
- initial project home と conversation surface は、basic operation において thread や channel concept に依存しない。
- package-provided surface は install されたときに project page、tab、pane、またはその他の declared placement として現れる。
- ユーザーは current context から作業を依頼できる。
- active work、approval waits、results、recovery states は product を dashboard 化せずに見える。
- package-provided surface は host-provided component、host-controlled typography、host-controlled accessibility、host-controlled navigation integration を通じて render される。

Navigation は、chat room や dashboard のような特定の metaphor を強制せず、project、page、package-provided surface を表現しなければなりません。threading、channel、vertical tree tabs などの構造は package または将来の built-in surface revision によって追加され得ます。具体的な navigation model は open design question として残します。

## Context Graph

Surface は shared context graph に参加します。graph は generic dump of UI state ではありません。ユーザーと Secretary が共同で reasoning できるものを構造化し、permission-aware に表現したものです。

minimal client baseline は次を提供しなければなりません。

- selected project。
- active surface と visible resource。
- project conversations。
- running jobs と delegated work。
- pending approvals。
- provenance、permissions、audit references。

package-provided surface は次を追加できます。

- open pages と package-provided resources。
- 安全に公開できる user selection と cursor focus。
- review obligations。
- domain-specific resource state。

すべての context contribution は provenance を持たなければなりません。package id、surface id、resource id、schema version、timestamp、permission scope、trust level です。resolver と Secretary は context を universal truth ではなく、provenance 付きの claimed state として扱わなければなりません。

## Actions

Surface は action を実行しません。package が宣言した action を propose します。Surface Protocol Resolver は proposal を policy、permission、approval、audit、関連する Secretary / service broker に route します。

surface は次のような action を propose できます。

- project conversation を開く、または更新する。
- project settings を変更する。
- installed packages を inspect する。
- package-provided operation を依頼する。
- package を install、update、disable、rollback する。

Permission と approval decision も protocol-mediated です。permission / approval surface は、ひとつの decision session のために resolver-created activation context を受け取ります。その response はその session に対してのみ valid であり、resolver によって audit されます。surface は自分で authority を作れません。

Action proposal には resolver-assigned correlation id が付与されます。Result は、その correlation id を provenance に含む context graph contribution として報告されます。action を propose した surface は、自分の correlation id に一致する context contribution を subscribe して result を追跡します。result を project-visible、requester-visible、audit-only のどれにするかは surface ではなく resolver が決定します。resolver は、result content の visibility に関わらず、route したすべての action に対して最低でも requester-visible な completion acknowledgment を届けなければなりません。

## Bounded Edit Model

Interactive surface は、draft text、field focus、selection、incomplete form value など、declared editable region のための provisional local state を保持できます。Provisional state は context graph state ではなく、canonical data でも hidden authority でもありません。

Editable region は presentation schema の中で input type、validation rule、permission scope、commit action、discard behavior、recovery behavior、accessibility requirement を宣言しなければなりません。resolver は committed edit を action proposal として validate します。Intermediate keystroke、cursor movement、local draft change は、package が safe で rate-limited な live update channel を明示的に宣言しない限り、brokered action にはなりません。

Package は provisional state を使って canonical data を mutate したり、permission を bypass したり、unbounded local state machine を作ったりしてはいけません。surface が suspended、degraded、destroyed になった場合、resolver は declared recovery behavior に従って provisional state を preserve、discard、または user に確認できます。

## Presentation

Presentation は Surface Protocol の semantic display layer です。Package は arbitrary SwiftUI、JavaScript、native client code を提供しません。Package が提供するのは、host が built-in native component で render する structured declaration、schema、strings、icons、resources、action metadata です。

Presentation layer は、適用される場合の iOS / App Store compliance と、macOS の platform safety のために十分制約されていなければなりません。

- downloaded client code を使わない。
- Turing-complete rendering language を持たない。
- arbitrary native API access を持たない。
- canonical data の hidden mutation をしない。
- typography、accessibility、command placement、warnings は host-controlled である。
- component が unavailable な場合に graceful fallback する。

State と logic は context graph、Secretary、services、action brokers に属します。Presentation は validated snapshot を render し、declared action を propose します。
baseline job / work visibility は generic host-baseline container で render できなければなりません。package-specific view はそれらの container を specialize できますが、baseline は domain-specific な agent / job component に依存してはいけません。

## Component Catalog And Specialization

native component catalog は host-provided な closed set です。Package は install 時に新しい client component implementation を追加できません。新しい component type には host release、または既存 component と同じ declaration / schema constraint に従う host-validated semantic component profile が必要です。

initial implementation では catalog を closed として扱います。将来の release では、package が executable UI code を配らずに新しい semantic component type を宣言できる host-validated semantic component profile を追加できます。その profile は bounded schema、declared interaction、fallback behavior、accessibility requirement、resolver validation を持つ structured declaration のままでなければなりません。

Package は code ではなく declaration によって host component を specialize します。Specialization には次を含められます。

- catalog からの semantic component choice。
- declared schema への data binding。
- field label、ordering、grouping、empty state。
- icon と string resources。
- action declaration と risk metadata。
- unsupported field / component の fallback presentation。

Specialization には次を含めてはいけません。

- arbitrary rendering logic。
- Turing-complete template。
- downloaded native、SwiftUI、JavaScript、WebView code。
- direct native API access。
- canonical data を mutate する hidden local state machine。

specialization の schema expressiveness には上限が必要です。schema は conditional rendering logic、固定深度を超える recursive nesting、他 field から導出される computed field を support してはいけません。resolver は、presentation schema がこの境界を超える package を surface mount 前に reject しなければなりません。

これは中心的な妥協点です。Package は structured specialization によって rich で domain-specific な surface を作れます。一方で Atelia は native rendering、accessibility、reviewability、platform safety を host control の下に保ちます。

## Security Boundaries

Atelia は iOS と general platform safety のため、package を executable client plugin ではなく structured data と brokered capability として説明しなければなりません。

iOS では、すべての extension package は non-executable structured declaration でなければなりません。host は、source に関係なく package が downloaded code によって app functionality を導入または変更できないことを App Store review に説明できる必要があります。

Package は次をしてはいけません。

- client UI code を download / execute する。
- UI を所有することで host permissions を bypass する。
- native platform API に直接 access する。
- trust level や activation context を自分で claim する。
- provenance、permission use、blocked state、security warnings を隠す。
- declared action、permission、service boundary の外で Secretary に作業を実行させる。

Extension-to-Secretary boundary は presentation boundary と同じくらい重要です。Package は declared action と service を通じてのみ brokered operation を request できます。Secretary を unbounded computation や automation escape hatch にしてはいけません。

## Non-Goals

Atelia Mac は workspace host であり、extension card を並べる static dashboard ではありません。

- Built-in packages は extension packages から利用できない private UI system ではない。
- Package は UI を所有することで host permissions を bypass してはいけない。
- Protocol-first は、すべての surface が同じ見た目であることを意味しない。
- Channel、thread、dashboard structure は base metaphor として必須ではない。

## macOS Beta Launch Gate

Atelia Mac package resolution は、beta で ship する前に host が次を提供していなければなりません。

- package metadata display と source labeling
- permission consent と permission diff presentation
- disable / rollback
- resolver rejection reason display
- install、update、rollback、safe mode entry の audit inspection
- package resolution failure 時の safe mode entry
- installed、bundled official、user-selected package の extension inspector

## Architectural Prerequisites

これらは protocol behavior を定義するため、implementation の前に決める必要があります。

- [Surface Protocol](../../atelia/docs/surface-protocol.ja.md): declaration、lifecycle、context、action routing、trust derivation のための normative client surface contract。
- [Component Catalog Reference](../../atelia/docs/component-catalog.ja.md): initial component catalog と semantic contract。
- surface は project space 内でどの程度 layout authority を宣言できるか。
- navigation placement protocol は何か。conflict resolution と context graph representation を含む。
- host slot、built-in-surface slot、context node type、composition mode、priority、conflict resolution のための first-class attachment point semantics は何か。
- bundled official package は manifest、permission、trust class、criticality をどう宣言するか。
- Host policy schema: trust threshold、criticality eligibility、platform divergence record、default enablement、platform profiles。
- [iOS Package Distribution Profile](../../atelia/docs/ios-package-distribution.ja.md): creator/runtime environment boundary、native API limit、consent、indexing、moderation、source policy、iOS policy を超える package の degradation。
- [Context Graph Specification](../../atelia/docs/context-graph.ja.md): node taxonomy、visibility class、redaction、trust weighting、staleness、retraction、Secretary reasoning eligibility。
- [Broker Boundary Specification](../../atelia/docs/broker-boundary.ja.md): Secretary、Resolver、Service Broker、Policy Engine の責務。
- [Package Resolution And Migration](../../atelia/docs/package-resolution-migration.ja.md): open surface、schema change、draft state、context node、audit trail、downgrade、rollback、safe mode。
- [Package Sharing And Source Policy](../../atelia/docs/package-sharing-source-policy.ja.md): source class、sharing boundary、monetization gate。
- [Content Safety And Moderation](../../atelia/docs/content-safety-moderation.ja.md): package metadata safety、reporting、blocking、content policy。
- [Agent-Authored Package Flow](../../atelia/docs/agent-authored-package-flow.ja.md): agent-created package proposal、consent、audit、rollback。
- [App Review Notes](../../atelia/docs/app-review-notes.ja.md): App Store review framing と launch gate。

## Open Design Questions

- Atelia は package-provided navigation を generic plugin menu に劣化させずにどう提示するべきか。
- presentation expressiveness は platform-safe のままどこまで広げられるか。
- vertical tree tabs、channel-like structure、または別の navigation model を default project-space metaphor にするべきか。
