# Atelia Mac

[日本語版 README](README.ja.md)

Atelia Mac is the native macOS client for operating Atelia Secretary beta.

This repository owns macOS-specific UI, windowing, notifications, file access,
Git / review surfaces, terminal, Hook / automation / extension management, and
voice operation. Shared logic lives in `atelia-kit`.

Within AEP, Atelia Mac is a reference presentation host. It renders semantic,
permission-aware AEP presentation surfaces with native Swift components. It does
not install or execute arbitrary downloaded client UI code.

## First Operating Surface

The beta opens on the Atelia surface. It is the default Mac working surface for
Secretary: project and thread switching, agent task status, Git branch /
worktree / diff / commit / push / PR actions, the in-app terminal, review queue,
voice operation, and connection management all live in one place.

The first surface is designed for day-to-day operator work. It keeps the current
work visible, lets the user inspect changes and review results, and makes it
easy to move from one task to the next without leaving the client. Browser use,
computer use, and deeper extension management stay out of the initial beta
surface.

## Initial Scope

- Atelia surface
- Projects and threads
- Multiple agent task status
- Git review surface
- Automatic review result display
- In-app terminal
- Review queue
- Voice operation
- Hooks, automations, and basic runtime extension usage
- Connection management for the Atelia Secretary daemon
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
