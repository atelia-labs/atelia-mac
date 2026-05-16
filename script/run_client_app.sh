#!/usr/bin/env bash
set -euo pipefail

swift build --product AteliaMacClient
app_binary="$(swift build --show-bin-path)/AteliaMacClient"
"${app_binary}"
