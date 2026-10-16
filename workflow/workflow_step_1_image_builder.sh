#!/usr/bin/env bash
# Stage 1: choose agent images (and OpenClaw version when applicable).
# Stage 2: choose whether to add the shared safety_research toolset.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "${SCRIPT_DIR}/build_images.py" "$@"
