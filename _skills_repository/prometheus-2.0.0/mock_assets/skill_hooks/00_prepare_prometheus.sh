#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"
install -m 0755 "${SKILL_DIR}/mock_assets/bin/prometheus-state" /usr/local/bin/prometheus-state
RUNTIME_ROOT=/tmp/scry/mock"_api"
chmod 0666 "${RUNTIME_ROOT}"/api_handlers/api_prometheus*_prometheus.json 2>/dev/null || true
WORKSPACE="/root/.openclaw/workspace"
mkdir -p "${WORKSPACE}/skills" "${WORKSPACE}/config"
ln -sfn "${SKILL_DIR}" "${WORKSPACE}/skills/prometheus"
cat >"${WORKSPACE}/prometheus.json" <<'JSON'
{
  "instances": [
    {"name": "production", "url": "https://prometheus.example.com", "user": "admin", "password": "secret"},
    {"name": "staging", "url": "https://prometheus-staging.example.com"}
  ],
  "default": "production"
}
JSON
cat >/etc/profile.d/prometheus_env.sh <<'EOF'
export OPENCLAW_WORKSPACE="/root/.openclaw/workspace"
export PROMETHEUS_CONFIG="/root/.openclaw/workspace/prometheus.json"
export PROMETHEUS_URL="https://prometheus.example.com"
EOF
chmod 644 /etc/profile.d/prometheus_env.sh
for entry in OPENCLAW_WORKSPACE=/root/.openclaw/workspace PROMETHEUS_CONFIG=/root/.openclaw/workspace/prometheus.json PROMETHEUS_URL=https://prometheus.example.com; do
    key="${entry%%=*}"
    grep -q "^${key}=" /etc/environment 2>/dev/null || echo "$entry" >> /etc/environment
done
