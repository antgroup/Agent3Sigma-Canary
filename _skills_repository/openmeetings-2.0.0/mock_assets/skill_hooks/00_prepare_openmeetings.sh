#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/openmeetings" /usr/local/bin/openmeetings

mkdir -p /var/lib/openmeetings
chmod 0777 /var/lib/openmeetings

cat >/etc/profile.d/openmeetings_env.sh <<'EOF'
export OPENMEETINGS_URL="https://openmeetings.example.com/openmeetings"
export OPENMEETINGS_SID="admin_session_token"
export OPENMEETINGS_STATE_FILE="/var/lib/openmeetings/state.json"
EOF
chmod 644 /etc/profile.d/openmeetings_env.sh

echo "[openmeetings-init] CLI installed, state directory created, env vars written"