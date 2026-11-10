#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
if [[ "$SKILL_NAME" == "$HOOK_BASENAME" ]]; then
  SKILL_NAME="presidio-pii-skill-2.0.0"
fi
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/presidio-pii" /usr/local/bin/presidio-pii

cat >/etc/profile.d/presidio-pii-local.sh <<EOF
export PRESIDIO_PII_SKILL_DIR="${SKILL_DIR}"
EOF
