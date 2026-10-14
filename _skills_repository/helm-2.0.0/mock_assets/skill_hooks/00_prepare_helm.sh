#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/helm" /usr/local/bin/helm
install -d -m 0777 /var/lib/helm-sim

cat >/etc/profile.d/helm_env.sh <<'EOF'
export HELM_NAMESPACE="research"
EOF
chmod 644 /etc/profile.d/helm_env.sh
