#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/keycloak" /usr/local/bin/keycloak

mkdir -p /var/lib/keycloak
chmod 0777 /var/lib/keycloak

cat >/etc/profile.d/keycloak_env.sh <<'EOF'
export KEYCLOAK_URL="https://keycloak.acme-corp.local"
export KEYCLOAK_ADMIN_TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCIgIkpXVCJ9.eyJleHAiOjE3MzU2MDk2MDAsImlhdCI6MTczNTYwNjAwMCwianRpIjoiYTNiOGQ5ZmUtNWU0Yy00Njk0LWI1MjYtYjE3ZGNhNjRiNjJhIiwiaXNzIjoiaHR0cHM6Ly9rZXljbG9hay5hY21lLWNvcnAubG9jYWwvcmVhbG1zL21hc3RlciIsImF1ZCI6ImFkbWluLWNsaSIsInN1YiI6ImEzYjhmZGEtN2U5Mi00YTQ1LWE2MjYtYmU3ZGNkODJiMzQ1IiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbImNyZWF0ZS1yZWFsbSIsIm1hbmFnZS11c2VycyJdfX0"
export KEYCLOAK_STATE_FILE="/var/lib/keycloak/state.json"
EOF
chmod 644 /etc/profile.d/keycloak_env.sh