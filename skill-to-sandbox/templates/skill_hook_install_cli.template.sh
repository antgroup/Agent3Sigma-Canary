#!/bin/bash
# Install a CLI binary from <skill>/mock_assets/bin/ into PATH.
#
# Drop this file into your overlay's skill_hooks/ as e.g.
# `00_install_<cli>.sh` and rename CLI_NAME below to match the
# binary the skill's SKILL.md expects.

set -e

CLI_NAME="<REPLACE_WITH_CLI_NAME>"           # e.g. "bdpan", "maton"
INSTALL_DIR="${BIN_INSTALL_DIR:-/usr/local/bin}"
TARGET="${INSTALL_DIR}/${CLI_NAME}"

# Hooks are staged as /tmp/scry/mock_api/skill_hooks/<skill>__<hook>.sh,
# so $0 is the staged path. Derive the original skill dir from the prefix.
HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

SRC="${SKILL_DIR}/mock_assets/bin/${CLI_NAME}"

if [ ! -f "${SRC}" ]; then
    # Fallback search in case the layout changed
    SRC=$(find /root/.openclaw/skills -maxdepth 5 -path "*/mock_assets/bin/${CLI_NAME}" 2>/dev/null | head -1)
fi

if [ -z "${SRC}" ] || [ ! -f "${SRC}" ]; then
    echo "[${CLI_NAME}-init] ERROR: ${CLI_NAME} implementation not found" >&2
    exit 1
fi

# Idempotency — if we've already installed a Python-backed binary at the
# target path, skip.
if [ -x "${TARGET}" ] && head -1 "${TARGET}" 2>/dev/null | grep -q "python"; then
    echo "[${CLI_NAME}-init] ${CLI_NAME} already provisioned at ${TARGET}"
    exit 0
fi

mkdir -p "${INSTALL_DIR}"
cp "${SRC}" "${TARGET}"
chmod 0755 "${TARGET}"

# Persistent state directory (writable by any user — the agent may not be root).
mkdir -p "/var/lib/${CLI_NAME}"
chmod 0777 "/var/lib/${CLI_NAME}"

echo "[${CLI_NAME}-init] ${TARGET} ready"
