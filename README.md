# Atelia Mac

[日本語版 README](README.ja.md)

Atelia Mac is the native macOS client for operating Atelia Secretary beta.

This repository owns the macOS-native Atelia shell and Surface Protocol Resolver:
windowing, project space, built-in package resolution, presentation hosting,
permissions, approvals, audit visibility, extension inspection, and platform
integration. Rich product areas such as Git, review, terminal, browser,
documents, calendar, tasks, and media are delivered as bundled official
packages or third-party extension packages. Shared logic lives in `atelia-kit`.

Within AEP, Atelia Mac is a reference presentation host. It renders semantic,
permission-aware AEP presentation surfaces with native Swift components. It does
not install or execute arbitrary downloaded client UI code.

Atelia Mac's default UI must be declared through the same Surface Protocol as
extension-provided UI. The default Mac experience is a minimal built-in package
set, not a privileged UI layer separate from extensions. The native shell
resolves that package set through the same Surface Protocol as extension
packages. See [Standard Surfaces](docs/standard-surfaces.md).

## First Operating Surface

The beta opens on the Atelia project space. The minimal client baseline provides
project selection, project conversation, extension installation and inspection,
settings, connection management, permissions, approvals, audit visibility, and
recovery surfaces.

Day-to-day work becomes rich through bundled official packages and
third-party extension packages that join the same project space. A Git or
terminal experience may ship with Atelia as an official package, but it must
still use the same presentation, context, permission, and action model rather
than hidden client core.

## Initial Scope

- Atelia project space
- Project home surface
- Project conversation
- Minimal project navigation
- Connection management for the Atelia Secretary daemon
- Permission, approval, audit, and recovery built-in package surfaces
- Extension installation, inspection, disabling, rollback, and safe mode
- AEP semantic presentation renderer subset
- Settings

## Future Scope

- bundled official packages for Git, review, terminal, documents, browser,
  tasks, calendar, notes, media, and other high-value workflows
- third-party package ecosystem
- future host-extension integration profiles, subject to platform policy review

## Development

This repository starts with a Swift package for client core before an Xcode app
target is added.

```sh
swift test
```
