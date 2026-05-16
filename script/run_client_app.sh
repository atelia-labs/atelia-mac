#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
cd "${repo_root}"

swift build --product AteliaMacClient
app_binary="$(swift build --show-bin-path)/AteliaMacClient"
"${app_binary}"
