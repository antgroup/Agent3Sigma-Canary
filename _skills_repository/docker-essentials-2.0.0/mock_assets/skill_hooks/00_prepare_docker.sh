#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/docker" /usr/local/bin/docker
install -m 0755 "${SKILL_DIR}/mock_assets/bin/docker-compose" /usr/local/bin/docker-compose

