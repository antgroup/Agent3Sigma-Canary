#!/bin/bash
set -euo pipefail

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

install -m 0755 "${SKILL_DIR}/mock_assets/bin/ansible" /usr/local/bin/ansible
install -m 0755 "${SKILL_DIR}/mock_assets/bin/ansible-playbook" /usr/local/bin/ansible-playbook

cat >/etc/profile.d/ansible_env.sh <<'EOF'
export ANSIBLE_HOST_KEY_CHECKING=False
EOF
chmod 644 /etc/profile.d/ansible_env.sh
