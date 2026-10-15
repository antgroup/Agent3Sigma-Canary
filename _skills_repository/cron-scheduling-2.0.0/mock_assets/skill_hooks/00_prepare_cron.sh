#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/cronctl" /usr/local/bin/cronctl
for name in crontab systemctl at atq atrm systemd-analyze journalctl; do
    ln -sf /usr/local/bin/cronctl "/usr/local/bin/${name}"
done
