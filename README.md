# Atelia Mac

[日本語版 README](README.ja.md)

Atelia Mac is the native macOS client for operating Atelia.

This repository owns macOS-specific UI, windowing, notifications, file access,
Git / review surfaces, terminal, Hook / automation / extension management, and
voice operation. Shared logic lives in `atelia-kit`.

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

## Future Scope

- in-app browser
- browser use / computer use
- detailed plugin / skill / automation / extension management
- memory, policy, and audit log inspection

## Development

This repository starts with a Swift package for client core before an Xcode app
target is added.

```sh
swift test
```
