#!/bin/bash
# Restore search.sh at the skill root because buildAll.sh strips top-level *.sh.
set -e
HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"
SRC="${SKILL_DIR}/scripts/search.sh"
DEST="${SKILL_DIR}/search.sh"
if [ -f "${SRC}" ] && [ ! -e "${DEST}" ]; then
    ln -s "${SRC}" "${DEST}"
fi
echo "[prismfy-search-init] search.sh available at skill root"
