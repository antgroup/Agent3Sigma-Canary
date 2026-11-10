#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/orangehrm" /usr/local/bin/orangehrm

mkdir -p /var/lib/orangehrm

cat >/etc/profile.d/orangehrm_env.sh <<'EOF'
export ORANGEHRM_URL="https://orangehrm.example.com"
export ORANGEHRM_TOKEN="local_orangehrm_token"
EOF
chmod 644 /etc/profile.d/orangehrm_env.sh