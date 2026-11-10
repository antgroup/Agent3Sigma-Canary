#!/bin/bash
set -e
command -v node >/dev/null
node --version
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENPROJECT_DATA_DIR="${OPENPROJECT_DATA_DIR:-${SCRIPT_DIR}/data}" node "${SCRIPT_DIR}/scripts/openproject.mjs" project-list >/dev/null
echo "openproject environment OK"
