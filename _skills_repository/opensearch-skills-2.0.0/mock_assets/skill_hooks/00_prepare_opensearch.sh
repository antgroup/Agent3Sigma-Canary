#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/opensearch-ops" /usr/local/bin/opensearch-ops
install -m 0755 "${SKILL_DIR}/mock_assets/bin/uv" /usr/local/bin/uv

cat >/etc/profile.d/opensearch_env.sh <<'EOF'
export OPENSEARCH_URL="https://localhost:9200"
export OPENSEARCH_INITIAL_ADMIN_PASSWORD="admin"
EOF
chmod 644 /etc/profile.d/opensearch_env.sh
