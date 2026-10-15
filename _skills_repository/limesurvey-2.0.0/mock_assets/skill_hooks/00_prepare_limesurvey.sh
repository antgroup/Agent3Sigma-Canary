#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/limesurvey" /usr/local/bin/limesurvey
install -d -m 0777 /var/lib/limesurvey

cat >/etc/profile.d/limesurvey_env.sh <<'EOF'
export LIMESURVEY_URL="https://survey.example.com/index.php/admin/remotecontrol"
export LIMESURVEY_USER="service_account"
export LIMESURVEY_PASSWORD="service_password"
EOF
chmod 644 /etc/profile.d/limesurvey_env.sh
