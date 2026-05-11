# Atelia Mac

[日本語版 README](README.ja.md)

Atelia Mac is the native macOS client for operating a user-owned Atelia harness
through Atelia Secretary: the user's own workspace of packages, surfaces,
workflows, agents, and brokered actions.

This repository owns the macOS-native Atelia shell and Surface Protocol Resolver:
windowing, project space, built-in package resolution, presentation hosting,
permissions, approvals, audit visibility, package inspection, and platform
integration. Rich product areas such as documents, browser, tasks, calendar,
notes, media, GitHub, review, terminal, and automations are delivered as bundled official
packages or user-selected / registry-verified packages. Shared logic lives in
`atelia-kit`.

Within AEP, Atelia Mac is a reference presentation host. It renders semantic,
permission-aware AEP presentation surfaces with native Swift components. It does
not run Secretary, install executable package code, load package-supplied web
runtime UI, or expose platform APIs to packages.

Atelia Mac's default UI must be declared through the same Surface Protocol as
package-provided UI. The default Mac experience is a minimal built-in package
set, not a privileged UI layer separate from packages. The native shell resolves
that package set through the same Surface Protocol as other packages. See
[Standard Surfaces](docs/standard-surfaces.md).

## First Operating Surface

The beta opens on the Atelia project space. The minimal client baseline provides
project selection, project conversation, package installation and inspection,
settings, connection management, permissions, approvals, audit visibility, and
recovery surfaces.

Day-to-day work becomes rich through bundled official packages and
user-selected / registry-verified packages that join the same project space. A
Git or terminal experience may ship with Atelia as an official package, but it
must still use the same presentation, context, permission, and action model
rather than hidden client core.

## Initial Scope

- Atelia project space (`project-space`)
- Project home surface (`project-home`)
- Project conversation (`project-conversation`)
- Project selection and onboarding (`project-selection-onboarding`)
- Minimal project navigation (`project-navigation`)
- Connection management for the Atelia Secretary daemon (`secretary-connection`)
- Permission, approval, audit, and recovery built-in package surfaces (`permission-recovery`)
- Package installation, inspection, disabling, rollback, and safe mode (`package-management`)
- AEP semantic presentation renderer subset (`presentation-renderer`)
- Settings (`settings`)

## Future Scope

- bundled official packages for documents, browser, tasks, calendar, notes,
  media, GitHub, review, terminal, automations, and other high-value workflows
- package install, inspect, validate, remix, and GitHub-backed publication flows
- registry search and trust-index review surfaces

## Development

This repository starts with a Swift package for client core before an Xcode app
target is added.

```sh
swift test
```
