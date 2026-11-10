#!/bin/bash
# Restore reference/ docs next to SKILL.md.

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

echo "[bdpan-init] reference docs ready"
