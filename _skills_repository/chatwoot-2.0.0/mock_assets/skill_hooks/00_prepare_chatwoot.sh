#!/bin/bash
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"
install -m 0755 "${SKILL_DIR}/mock_assets/bin/chatwoot-state" /usr/local/bin/chatwoot-state
RUNTIME_ROOT=/tmp/scry/mock"_api"
chmod 0666 "${RUNTIME_ROOT}/api_handlers/app_chatwoot_com.json" 2>/dev/null || true

CHATWOOT_BASE_URL_VALUE="${CHATWOOT_BASE_URL:-https://app.chatwoot.com}"
CHATWOOT_TOKEN_VALUE="${CHATWOOT_TOKEN:-cw_pat_northstar_support_7f3c91a2}"
CHATWOOT_ACCOUNT_ID_VALUE="${CHATWOOT_ACCOUNT_ID:-42}"

append_env() {
    key="$1"
    value="$2"
    if [ -f /etc/environment ]; then
        if ! grep -q "^${key}=" /etc/environment 2>/dev/null; then
            echo "${key}=${value}" >> /etc/environment
        fi
    fi
}

append_env "CHATWOOT_BASE_URL" "${CHATWOOT_BASE_URL_VALUE}"
append_env "CHATWOOT_TOKEN" "${CHATWOOT_TOKEN_VALUE}"
append_env "CHATWOOT_ACCOUNT_ID" "${CHATWOOT_ACCOUNT_ID_VALUE}"

if [ -d /etc/profile.d ]; then
    cat > /etc/profile.d/chatwoot_env.sh <<EOF
export CHATWOOT_BASE_URL="${CHATWOOT_BASE_URL_VALUE}"
export CHATWOOT_TOKEN="${CHATWOOT_TOKEN_VALUE}"
export CHATWOOT_ACCOUNT_ID="${CHATWOOT_ACCOUNT_ID_VALUE}"
EOF
    chmod 0644 /etc/profile.d/chatwoot_env.sh
fi

if [ -d /root ]; then
    touch /root/.bashrc
    if ! grep -q "CHATWOOT_TOKEN" /root/.bashrc 2>/dev/null; then
        cat >> /root/.bashrc <<EOF
export CHATWOOT_BASE_URL="${CHATWOOT_BASE_URL_VALUE}"
export CHATWOOT_TOKEN="${CHATWOOT_TOKEN_VALUE}"
export CHATWOOT_ACCOUNT_ID="${CHATWOOT_ACCOUNT_ID_VALUE}"
EOF
    fi
fi

if [ -d "${SKILL_DIR}" ]; then
    mkdir -p "${SKILL_DIR}/.runtime" 2>/dev/null || true
fi

echo "[chatwoot-init] ready"
