#!/bin/bash
# Provide a default PRISMFY_API_KEY so the bundled search.sh works out of the box.
#
# Write to /etc/environment so PAM-managed processes (including
# `bash -c ...` and `subprocess.run([...])` from the agent) inherit it.
# Also keep /etc/profile.d/ so interactive/login shells echo it too.
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"
install -m 0755 "${SKILL_DIR}/mock_assets/bin/prismfy-search-state" /usr/local/bin/prismfy-search-state
RUNTIME_ROOT=/tmp/scry/mock"_api"
chmod 0666 "${RUNTIME_ROOT}/api_handlers/api_prismfy_io.json" 2>/dev/null || true

KEY_VALUE="${PRISMFY_API_KEY:-ss_live_4f8b2c1d9a3e5h6j8k0l2m4n}"

if [ -d /etc ] && ! grep -q "^PRISMFY_API_KEY=" /etc/environment 2>/dev/null; then
    echo "PRISMFY_API_KEY=${KEY_VALUE}" >> /etc/environment
fi

if [ -d /etc/profile.d ]; then
    printf 'export PRISMFY_API_KEY="%s"\n' "${KEY_VALUE}" > /etc/profile.d/prismfy_key.sh
    chmod 0644 /etc/profile.d/prismfy_key.sh
fi

echo "[prismfy-search-init] API key default provisioned"
