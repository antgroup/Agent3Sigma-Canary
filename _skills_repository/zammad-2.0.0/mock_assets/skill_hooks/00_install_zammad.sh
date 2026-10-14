#!/bin/bash
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"
SRC="${SKILL_DIR}/mock_assets/bin/zammad"

install -m 0755 "${SRC}" /usr/local/bin/zammad
mkdir -p /var/lib/zammad-cli
chmod 0777 /var/lib/zammad-cli
cat >/etc/profile.d/zammad_state.sh <<'EOF'
export ZAMMAD_STATE_FILE="/var/lib/zammad-cli/state.json"
EOF
chmod 0644 /etc/profile.d/zammad_state.sh
if ! grep -q '^ZAMMAD_STATE_FILE=' /etc/environment 2>/dev/null; then
    echo 'ZAMMAD_STATE_FILE=/var/lib/zammad-cli/state.json' >> /etc/environment
fi

echo "[zammad-init] command installed"
