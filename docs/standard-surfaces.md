# Standard Surfaces

Atelia Mac is not a fixed application with a few extension slots bolted onto it.
It is a native shell that contains a Surface Protocol Resolver. Every
user-facing surface, including the surfaces bundled with Atelia, must be
registered through package declarations and interpreted by that resolver.

The default UI has transparent distribution privileges: host-required
criticality, non-removability where required for baseline operation, and app
binary provenance recorded in host policy. It receives no hidden execution
authority and uses the same protocol, component catalog, action routing, context
graph, and permission model as every other package.

## Glossary

- **Shell**: the native macOS application container. It owns windows, platform
  integration, accessibility, secure storage, and the Surface Protocol Resolver.
  The shell is not itself a surface.
- **Surface Protocol Resolver**: the host-side interpreter for package manifests,
  surface declarations, context participation, action routing, lifecycle, trust,
  and presentation. It interprets structured declarations; it is not a downloaded
  code execution runtime.
- **Package**: the distribution unit that declares one or more surfaces,
  capabilities, schemas, actions, resources, and permissions.
- **Built-in package**: a package bundled inside the app binary. Built-in is a
  distribution fact, not a separate protocol model.
- **Extension package**: a package installed from a registry, repository, or
  user-selected source. It uses the same surface protocol as built-in packages.
- **Surface**: a protocol participant mounted inside project space. A surface
  belongs to a package, has lifecycle, may read or contribute context, may
  propose actions, and declares presentation.
- **Presentation**: the semantic display layer of a surface. A presentation
  declaration says what host-provided components should render from validated
  data. It is not arbitrary client UI code.
- **Context graph**: the structured, permission-aware project state shared by
  the user, the project Secretary, and eligible surfaces.
- **Action**: a declared proposal routed by the resolver through policy,
  permission, approval, audit, and Secretary / service brokers.
- **Activation context**: resolver-created session data that gives a mounted
  surface authority to answer a specific prompt, approval, recovery, or task
  flow. A surface cannot mint its own activation context.
- **Trust level**: package provenance derived by the resolver from platform
  signing, bundle membership, registry verification, and user install choices.
- **Host policy**: resolver-readable policy shipped with the host binary. It
  defines criticality eligibility, trust thresholds, default package enablement,
  default permission grants, and platform-specific divergence records. Host
  policy is versioned with the host release.

## Specification Home

This document defines the Surface Protocol architecture for Atelia Mac. The
normative Surface Protocol specification lives in the AEP specification family:
[Surface Protocol](../../atelia/docs/surface-protocol.md). Detailed declaration
schemas, attachment point semantics, field bindings, lifecycle state machines,
context subscription, action routing, and trust derivation must be defined
there or in documents it references.

## Protocol Layers

AEP Presentation is one layer of the broader Surface Protocol. It must not be
separate from the surface model.

The Surface Protocol includes:

- **Declaration**: package manifest, surface ids, capabilities, schemas,
  permissions, resources, and compatibility.
- **Lifecycle**: mount, activate, suspend, destroy, degrade, and recover.
- **Context**: subscribe, contribute, retract, provenance, visibility, and scope.
- **Action**: propose, route, confirm, approve, execute through brokers, audit,
  and report result.
- **Presentation**: host-rendered semantic components bound to validated data.
- **Trust**: provenance, trust level, criticality, allowed activation contexts,
  and authority limits.

This is a protocol for structured declarations and brokered actions. It must not
be described as a system for downloading or executing client code.

The concrete declaration format belongs in the Surface Protocol specification;
the first implementation must use a schema-validated format that the resolver
can parse before mounting a package.

## Normative Language

This document uses **must** for architectural invariants enforced by the shell,
resolver, host policy, or package validation. It uses **may** for allowed
capabilities and **should** only for product guidance with legitimate future
exceptions.

## Principle

All user-facing Atelia surfaces must use the same Surface Protocol. Built-in
packages and extension packages differ by distribution and trust level, not by a
private UI architecture.

- presentation is semantic and host-rendered;
- state enters the shared project context graph with provenance;
- actions route through the same permission, approval, and audit path;
- lifecycle and degradation are protocol states;
- built-in packages receive no hidden execution authority beyond explicit trust
  rules and activation contexts.

## Why This Matters

Atelia is intended to become a user's working and living space. Documents,
browser, calendar, tasks, notes, media, GitHub, terminal, reviews, automations,
and future tools can appear in one coherent client, but those
capabilities are package-provided surfaces, not assumptions built into the
initial client.

That breadth cannot be served by one hard-coded navigation hierarchy or one
universal screen layout. It also cannot be served by letting every package draw
arbitrary pixels with arbitrary behavior. The client needs a protocol-level
middle ground: flexible enough for many kinds of work, constrained enough to
remain understandable, native, inspectable, and safe.

When any package-provided surface, resource, or activity is open inside Atelia,
the user and the project Secretary can share the same context. This shared
context is the product value. The UI architecture must preserve it instead of
splitting the world into a privileged default app and secondary extension
panels.

## Shell

The shell is the native app container. It is not a surface and does not own
product UI directly. The shell provides:

- windows, native platform behavior, and accessibility;
- secure local storage and platform permission bridges;
- the Surface Protocol Resolver;
- built-in package registry resolution;
- native component catalog implementation;
- safe mode entry when package resolution fails.

The shell may expose unavoidable platform facts, such as code signing and app
bundle membership, to the resolver as trust assertions. Those assertions are data
fed into the protocol model, not hidden UI authority.

The client baseline must not own product-specific surfaces. It may provide the
shared primitives, native component catalog, platform permission bridges,
context contracts, action contracts, and brokered service boundaries that
packages need to create first-class experiences.

## Surfaces And Packages

Surfaces are hosted inside project space by the Surface Protocol Resolver. A
surface may come from a built-in package or an extension package. The initial
built-in package set is deliberately small:

- project home;
- project conversation;
- project selection and onboarding;
- extension installation, inspection, disabling, rollback, and safe mode;
- settings;
- permission, approval, audit, and recovery surfaces.

The built-in set must pass a strict test: a surface belongs there only when
Atelia cannot reach a usable fresh-install state without it, or when the surface
mediates trust, permission, recovery, or package safety decisions that the
resolver must guarantee. Any surface a user could reasonably obtain by enabling
a bundled official package must not become built-in client core.

Documents, browser, tasks, calendar, notes, media, GitHub, review, terminal,
and similar product areas arrive as bundled official packages or
third-party extension packages. They may feel native and central when installed,
but they are not part of the minimal client baseline. The architectural point is
distribution through the package model, not absence from the product.

## Surface Lifecycle

Every surface has lifecycle managed by the resolver:

- **available**: declared by an installed package and compatible with the host;
- **mounted**: placed in project space or a host slot;
- **active**: visible or receiving focus / activation context;
- **suspended**: preserved but not active;
- **degraded**: mounted through fallback presentation or reduced capability;
- **destroyed**: removed from the current project space.

Surfaces declare criticality:

- **host-required**: required for baseline operation, such as project
  conversation, permission prompts, approvals, audit visibility, and recovery.
  Only `host-shipped built-in` packages may claim this tier.
- **user-removable**: bundled or installed surfaces the user can disable.
- **optional**: surfaces that appear only when enabled or requested.

Criticality is not self-authorized. The resolver accepts or downgrades a claimed
criticality tier based on package trust level and host policy.

## Trust Model

Trust is derived from package provenance, not from a surface's own claim.

Package distribution and criticality are separate axes:

| Package class | Distribution | Default criticality |
| --- | --- | --- |
| `host-shipped built-in` | bundled in the app binary and tied to platform code signing | may claim `host-required` when needed for baseline operation |
| `bundled official` | distributed by Atelia, installed by default or recommended during setup | usually `user-removable`; may become non-removable only when explicit host policy records a baseline requirement |
| `verified third-party` | distributed through a trusted registry with automated validation, signatures, and compatibility metadata | `user-removable` or `optional` |
| `unverified third-party` | explicitly installed by the user from an external source | `optional`; user policy may enable it, but cannot make it `host-required` |

These classes are distribution paths, not separate UI architectures. The
resolver must not grant a built-in or bundled official package a capability that
is structurally unavailable to third-party packages on the same platform. Any
exception must be recorded in host policy as a platform limitation.

Criticality is a lifecycle claim, not a distribution class. Distribution can
make a claim eligible, but the resolver still validates it against host policy.

Distribution trust affects how a package is bundled, signed, updated, reviewed,
and initially enabled. It does not bypass permission checks at use time, action
routing, audit logging, degradation, inspection, or context provenance. If a
platform constraint prevents a third-party package from receiving the same
treatment as a built-in or bundled official package, host policy must record that
as a platform limitation, not a trust preference. Official packages can be
trusted defaults without becoming hidden client core.

## Default Experience

Protocol-first does not mean blank canvas or configuration-first. The default
must provide a coherent project space where:

- selecting a project opens the project workspace;
- the initial project home and conversation surface does not depend on thread
  or channel concepts for basic operation;
- package-provided surfaces appear as project pages, tabs, panes, or other
  declared placements when installed;
- the user can ask for work from the current context;
- active work, approval waits, results, and recovery states are visible without
  turning the product into a dashboard;
- package-provided surfaces render through host-provided components,
  host-controlled typography, host-controlled accessibility, and host-controlled
  navigation integration.

Navigation must express project, page, and package-provided surfaces without
forcing a specific metaphor such as chat rooms or dashboards. Threading,
channels, vertical tree tabs, and similar structures may be added by packages or
future built-in surface revisions; the concrete navigation model remains an open
design question.

## Context Graph

Surfaces participate in a shared context graph. The graph is not a generic dump
of UI state. It is a structured, permission-aware description of what the user
and Secretary can jointly reason about.

The minimal client baseline must provide:

- selected project;
- active surface and visible resource;
- project conversations;
- running jobs and delegated work;
- pending approvals;
- provenance, permissions, and audit references.

Package-provided surfaces may add:

- open pages and package-provided resources;
- user selections and cursor focus where safe to expose;
- review obligations;
- domain-specific resource state.

Every context contribution must carry provenance: package id, surface id,
resource id, schema version, timestamp, permission scope, and trust level. The
resolver and Secretary must treat context as claimed state with provenance, not
as universal truth.

## Actions

Surfaces do not execute actions. They propose actions declared by their package.
The Surface Protocol Resolver routes proposals through policy, permissions,
approvals, audit, and the relevant Secretary / service broker.

A surface may propose actions such as:

- open or update a project conversation;
- change project settings;
- inspect installed packages;
- request a package-provided operation;
- install, update, disable, or roll back a package.

Permission and approval decisions are also protocol-mediated. A permission or
approval surface receives a resolver-created activation context for one decision
session. Its response is valid only for that session and is audited by the
resolver. The surface cannot create its own authority.

Action proposals receive a resolver-assigned correlation id. Results are
reported as context graph contributions carrying that correlation id in
provenance. A surface that proposes an action tracks the result by subscribing to
context contributions matching its correlation ids. The resolver, not the
surface, decides whether a result is project-visible, requester-visible, or audit
only.
The resolver must deliver at least a requester-visible completion acknowledgment
for every action it routes, regardless of result content visibility.

## Bounded Edit Model

Interactive surfaces may hold provisional local state for declared editable
regions, such as draft text, field focus, selection, and incomplete form values.
Provisional state is not context graph state, not canonical data, and not hidden
authority.

Editable regions must be declared in the presentation schema with input type,
validation rules, permission scope, commit action, discard behavior, recovery
behavior, and accessibility requirements. The resolver validates committed edits
as action proposals. Intermediate keystrokes, cursor movement, and local draft
changes do not become brokered actions unless the package explicitly declares a
safe, rate-limited live update channel.

Packages must not use provisional state to mutate canonical data, bypass
permissions, or create an unbounded local state machine. If a surface is
suspended, degraded, or destroyed, the resolver may preserve, discard, or ask the
user about provisional state according to declared recovery behavior.

## Presentation

Presentation is the semantic display layer of the Surface Protocol. Packages do
not provide arbitrary SwiftUI, JavaScript, or native client code. They provide
structured declarations, schemas, strings, icons, resources, and action metadata
that the host renders with built-in native components.

The presentation layer must remain constrained enough for iOS and App Store
compliance where applicable, and for platform safety on macOS:

- no downloaded client code;
- no Turing-complete rendering language;
- no arbitrary native API access;
- no hidden mutation of canonical data;
- host-controlled typography, accessibility, command placement, and warnings;
- graceful fallback when a component is unavailable.

State and logic belong in the context graph, Secretary, services, and action
brokers. Presentation renders validated snapshots and proposes declared actions.
Baseline job and work visibility must be renderable through generic
host-baseline containers. Package-specific views may specialize those containers,
but the baseline must not depend on a domain-specific agent or job component.

## Component Catalog And Specialization

The native component catalog is a closed host-provided set. Packages cannot add
new client component implementations at install time. New component types require
a host release or a host-validated semantic component profile governed by the
same declaration and schema constraints as existing components.

The initial implementation treats the catalog as closed. Future releases may add
a host-validated semantic component profile that lets packages declare new
semantic component types without shipping executable UI code. Such profiles must
remain structured declarations with bounded schemas, declared interactions,
fallback behavior, accessibility requirements, and resolver validation.

Packages specialize host components by declaration, not code. Specialization may
include:

- semantic component choice from the catalog;
- data bindings to declared schemas;
- field labels, ordering, grouping, and empty states;
- icon and string resources;
- action declarations and risk metadata;
- fallback presentation for unsupported fields or components.

Specialization must not include:

- arbitrary rendering logic;
- Turing-complete templates;
- downloaded native, SwiftUI, JavaScript, or WebView code;
- direct native API access;
- hidden local state machines that mutate canonical data.

Schema expressiveness for specialization must be bounded. Schemas must not
support conditional rendering logic, recursive nesting beyond a fixed depth, or
computed fields derived from other fields. The resolver must reject packages
whose presentation schemas exceed these bounds before mounting the surface.

This is the core compromise: packages can produce rich, domain-specific surfaces
through structured specialization, while Atelia keeps native rendering,
accessibility, reviewability, and platform safety under host control.

## Security Boundaries

For iOS and general platform safety, Atelia must describe packages as
structured data and brokered capabilities, not executable client plugins.

On iOS, every extension package must remain a non-executable structured
declaration. The host must be able to show that no package, regardless of source,
can introduce or modify app functionality through downloaded code.

Packages must not:

- download or execute client UI code;
- bypass host permissions by owning UI;
- directly access native platform APIs;
- claim trust level or activation context for themselves;
- hide provenance, permission use, blocked state, or security warnings;
- cause Secretary to execute work outside declared action, permission, and
  service boundaries.

The extension-to-Secretary boundary is as important as the presentation boundary.
A package may request brokered operations only through declared actions and
services; it must not turn Secretary into an unbounded computation or automation
escape hatch.

## Non-Goals

Atelia Mac is a workspace host, not a static dashboard with extension cards.

- Built-in packages are not a private UI system unavailable to extension
  packages.
- Packages must not bypass host permissions by owning UI.
- Protocol-first does not mean every surface must look the same.
- Channel, thread, or dashboard structures are not mandatory base metaphors.

## macOS Beta Launch Gate

Atelia Mac package resolution should not ship in beta until the host provides:

- package metadata display and source labeling;
- permission consent and permission diff presentation;
- disable and rollback;
- resolver rejection reason display;
- audit inspection for install, update, rollback, and safe mode entry;
- safe mode entry when package resolution fails;
- extension inspector for installed, bundled official, and user-selected
  packages.

## Architectural Prerequisites

These questions block implementation because they define protocol behavior:

- [Surface Protocol](../../atelia/docs/surface-protocol.md): normative client
  surface contract for declaration, lifecycle, context, action routing, and
  trust derivation.
- [Component Catalog Reference](../../atelia/docs/component-catalog.md): initial
  component catalog and semantic contracts.
- How much layout authority may a surface declare inside project space?
- What is the navigation placement protocol, including conflict resolution and
  context graph representation?
- What are the first-class attachment point semantics for host slots,
  built-in-surface slots, context node types, composition mode, priority, and
  conflict resolution?
- How do bundled official packages declare manifests, permissions, trust class,
  and criticality?
- Host policy schema: trust thresholds, criticality eligibility, platform
  divergence records, default enablement, and platform profiles.
- [iOS Package Distribution Profile](../../atelia/docs/ios-package-distribution.md):
  creator/runtime environment boundary, native API limits, consent, indexing,
  moderation, source policy, and degradation for packages that exceed iOS policy.
- [Context Graph Specification](../../atelia/docs/context-graph.md): node
  taxonomy, visibility classes, redaction, trust weighting, staleness,
  retraction, and Secretary reasoning eligibility.
- [Broker Boundary Specification](../../atelia/docs/broker-boundary.md): Secretary,
  Resolver, Service Broker, and Policy Engine responsibilities.
- [Package Resolution And Migration](../../atelia/docs/package-resolution-migration.md):
  open surfaces, schema changes, draft state, context nodes, audit trail,
  downgrade, rollback, and safe mode.
- [Package Sharing And Source Policy](../../atelia/docs/package-sharing-source-policy.md):
  source classes, sharing boundary, and monetization gate.
- [Content Safety And Moderation](../../atelia/docs/content-safety-moderation.md):
  package metadata safety, reporting, blocking, and content policy.
- [Agent-Authored Package Flow](../../atelia/docs/agent-authored-package-flow.md):
  agent-created package proposal, consent, audit, and rollback.
- [App Review Notes](../../atelia/docs/app-review-notes.md): App Store review
  framing and launch gate.

## Open Design Questions

- How does Atelia present package-provided navigation without degrading into a
  generic plugin menu?
- How far can presentation expressiveness go while remaining platform-safe?
- Should vertical tree tabs, channel-like structures, or another navigation
  model become the default project-space metaphor?
