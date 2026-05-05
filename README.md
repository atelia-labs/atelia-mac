# Atelia Mac

[日本語版 README](README.ja.md)

Atelia Mac is the native macOS client for operating Atelia.

This repository owns macOS-specific UI, windowing, notifications, file access,
Git / review surfaces, terminal, Hook / automation / extension management, and
voice operation. Shared logic lives in `atelia-kit`.

Within AEP, Atelia Mac is a reference presentation host. It renders semantic,
permission-aware AEP presentation surfaces with native Swift components. It does
not install or execute arbitrary downloaded client UI code.

## Initial Scope

- project / thread list and switching
- status for multiple agent tasks
- Git branch / worktree / diff / commit / push / PR surfaces
- automatic review result display
- in-app terminal
- review queue
- voice operation
- Hook / automation / extension inspection
- connection management for the Atelia Secretary daemon
- AEP semantic presentation renderer subset
- extension install, permission diff, approval, review, settings, and audit
  surfaces

## Future Scope

- in-app browser
- browser use / computer use
- detailed plugin / skill / automation / extension management
- future high-trust native client extension profile, if approved separately
- memory, policy, and audit log inspection

## Development

This repository starts with a Swift package for client core before an Xcode app
target is added.

```sh
swift test
```
