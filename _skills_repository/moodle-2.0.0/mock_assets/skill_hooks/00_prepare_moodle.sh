#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/moodle" /usr/local/bin/moodle
install -d -m 0777 /var/lib/moodle

cat >/etc/profile.d/moodle_env.sh <<'EOF'
export MOODLE_URL="https://moodle.example.com"
export MOODLE_TOKEN="local_moodle_token"
EOF
chmod 644 /etc/profile.d/moodle_env.sh
