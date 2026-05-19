# PDH-175 Live E2E Evidence (Mac + Secretary)

This worktree adds an AppModel verifier harness that can run against a live
Secretary daemon. It does not claim full UI automation coverage. When an
authenticated daemon is available, it verifies the following chain through
`ClientAppModel`:

1. Register a local project through the existing-folder path.
2. Submit a command that maps to `filesystem.search`.
3. Confirm rendered tool output appears in the project Secretary conversation
   state.

## Command

```bash
cd /Users/yohaku/atelia-labs/atelia-mac-live-e2e
ATELIA_MAC_LIVE_E2E=1 \
ATELIA_DAEMON_HOST=127.0.0.1 \
ATELIA_DAEMON_PORT=8080 \
ATELIA_DAEMON_AUTH_TOKEN=<secretary token or unset only if daemon auth is disabled> \
ATELIA_E2E_PROJECT_PATH=/Users/yohaku/atelia-labs/atelia-mac-live-e2e \
ATELIA_E2E_COMMAND='search package' \
ATELIA_E2E_MAX_WAIT_MS=30000 \
./Scripts/pdh175-live-secretary-verifier.sh
```

The verifier records:

- Mac worktree SHA
- `Package.resolved` entry for `atelia-kit` (the dependency lock evidence)
- `atelia-kit` SwiftPM checkout metadata at `.build/checkouts/atelia-kit` when present
- atelia-secretary SHA when the sibling repo exists
- daemon endpoint
- project path and submitted command
- test command: `swift test --filter clientAppModelLiveSecretaryFilesystemSearchSmoke`
- result through the `swift test` exit code

## Test Name

- `clientAppModelLiveSecretaryFilesystemSearchSmoke`

## Remaining Evidence Gaps

This is stronger than fixture-only coverage, but it is not final MDP evidence
by itself until it has passed against an authenticated live Secretary daemon.
The current harness intentionally fails closed if the daemon rejects the request
with `401` or another HTTP error.

Full macOS UI automation is still not covered here. This lane does not include
a harness that launches the SwiftUI/AppKit executable, clicks through folder
selection, submits in the visible composer, and screenshots the rendered
conversation. The verifier instead exercises the same application model,
HTTP client, project registration, submit, render, and conversation-state path.
