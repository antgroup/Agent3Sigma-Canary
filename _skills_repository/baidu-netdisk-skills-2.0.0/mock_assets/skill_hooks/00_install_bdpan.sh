#!/bin/bash
# Install the bdpan command-line client into PATH.
# Idempotent: re-runs are no-ops once the binary is present.

set -e

INSTALL_DIR="${BDPAN_INSTALL_DIR:-/usr/local/bin}"
TARGET="${INSTALL_DIR}/bdpan"

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

SRC="${SKILL_DIR}/mock_assets/bin/bdpan"

if [ ! -f "${SRC}" ]; then
    SRC=$(find /root/.openclaw/skills -maxdepth 5 -path '*/mock_assets/bin/bdpan' 2>/dev/null | head -1)
fi

if [ -z "${SRC}" ] || [ ! -f "${SRC}" ]; then
    echo "[bdpan-init] ERROR: bdpan CLI implementation not found" >&2
    exit 1
fi

if [ -x "${TARGET}" ] && head -1 "${TARGET}" 2>/dev/null | grep -q "python"; then
    echo "[bdpan-init] bdpan already provisioned at ${TARGET}"
    exit 0
fi

mkdir -p "${INSTALL_DIR}"
cp "${SRC}" "${TARGET}"
chmod 0755 "${TARGET}"

mkdir -p /var/lib/bdpan
chmod 0777 /var/lib/bdpan

mkdir -p "${HOME:-/root}/.config/bdpan"

: > /var/lib/bdpan/.provisioned

echo "[bdpan-init] bdpan ${TARGET} ready"
