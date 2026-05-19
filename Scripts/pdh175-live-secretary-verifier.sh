#!/usr/bin/env bash

set -euo pipefail

WORKTREE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ATELIA_MAC_LIVE_E2E=1
export ATELIA_DAEMON_HOST="${ATELIA_DAEMON_HOST:-127.0.0.1}"
export ATELIA_DAEMON_PORT="${ATELIA_DAEMON_PORT:-8080}"
export ATELIA_E2E_PROJECT_PATH="${ATELIA_E2E_PROJECT_PATH:-$WORKTREE_ROOT}"
export ATELIA_E2E_COMMAND="${ATELIA_E2E_COMMAND:-search package}"
export ATELIA_E2E_MAX_WAIT_MS="${ATELIA_E2E_MAX_WAIT_MS:-30000}"

log_repo_ref() {
  local label="$1"
  local repo_path="$2"
  if [ ! -d "$repo_path/.git" ]; then
    printf '%s branch: <missing> (%s not found)\n' "$label" "$repo_path"
    return
  fi

  local branch
  branch="$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  branch="${branch:-<unknown>}"
  local sha
  sha="$(git -C "$repo_path" rev-parse --short HEAD 2>/dev/null || true)"
  sha="${sha:-<unknown>}"
  printf '%s branch: %s (%s)\n' "$label" "$branch" "$sha"
}

printf 'PDH-175 live verifier\n'
printf 'Mac repo: %s (%s)\n' "$WORKTREE_ROOT" "$(git -C "$WORKTREE_ROOT" rev-parse --short HEAD)"
log_repo_ref "atelia-kit" "$WORKTREE_ROOT/../atelia-kit"
log_repo_ref "atelia-secretary" "$WORKTREE_ROOT/../atelia-secretary"
printf 'daemon endpoint: %s:%s\n' "$ATELIA_DAEMON_HOST" "$ATELIA_DAEMON_PORT"
printf 'project path: %s\n' "$ATELIA_E2E_PROJECT_PATH"
printf 'project command: %s\n' "$ATELIA_E2E_COMMAND"
printf 'max wait ms: %s\n' "$ATELIA_E2E_MAX_WAIT_MS"
declare -a pdh175_test_command=(swift test --filter clientAppModelLiveSecretaryFilesystemSearchSmoke)
printf 'test command: %s\n' "${pdh175_test_command[*]}"

if [[ -n "${ATELIA_DAEMON_AUTH_TOKEN:-}" ]]; then
    printf 'using ATELIA_DAEMON_AUTH_TOKEN from environment\n'
else
    printf 'ATELIA_DAEMON_AUTH_TOKEN is not set; continuing with unauthenticated endpoint access when supported\n'
fi

printf 'running live model verifier test...\n'
cd "$WORKTREE_ROOT"
"${pdh175_test_command[@]}"
