#!/usr/bin/env bash
# Build existing agent variants with optional research tools and OpenClaw versions.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "${SCRIPT_DIR}/build_images.py" "$@"
