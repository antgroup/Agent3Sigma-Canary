#!/bin/bash
# Restore <skill>/reference/ from mock_assets/reference/.
#
# Background: AgentCanary's buildAll.sh only preserves scripts/,
# mock_assets/, SKILL.md, and executable binaries at the skill-dir
# root. Any other directory (notably reference/, which many ClawHub
# skills ship next to SKILL.md and link to with ./reference/foo.md)
# is stripped. We ship reference docs inside mock_assets/reference/
# so they survive packaging, and use this hook to put them back where
# SKILL.md expects them.
#
# Drop this file into your overlay's skill_hooks/ as e.g.
# `01_install_reference.sh` and adjust the prefix if you need a
# different ordering relative to other hooks.

set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

SRC="${SKILL_DIR}/mock_assets/reference"
DEST="${SKILL_DIR}/reference"

if [ ! -d "${SRC}" ]; then
    exit 0
fi

mkdir -p "${DEST}"
cp -r "${SRC}/." "${DEST}/"

echo "[reference-init] reference docs ready at ${DEST}"
