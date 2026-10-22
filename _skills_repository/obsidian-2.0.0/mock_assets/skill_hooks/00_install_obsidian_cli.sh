#!/bin/bash
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

BIN_SRC="${SKILL_DIR}/mock_assets/bin/obsidian-cli"
BIN_DST="/usr/local/bin/obsidian-cli"
STATE_DIR="/var/lib/obsidian-cli"

install -m 0755 "${BIN_SRC}" "${BIN_DST}"
mkdir -p "${STATE_DIR}"
chmod 0777 "${STATE_DIR}"

"${BIN_DST}" print-default --path-only >/dev/null

echo "[obsidian-cli-init] ready"
exit 0
