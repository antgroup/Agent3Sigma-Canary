#!/bin/bash
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

SUITECRM_URL_VALUE="${SUITECRM_URL:-https://crm.rivermarksystems.com}"
SUITECRM_CLIENT_ID_VALUE="${SUITECRM_CLIENT_ID:-suitecrm-client-7f3c91a2}"
SUITECRM_CLIENT_SECRET_VALUE="${SUITECRM_CLIENT_SECRET:-suitecrm-secret-94c1e7b3a5d8}"
SUITECRM_USER_VALUE="${SUITECRM_USER:-suite.ops}"
SUITECRM_PASS_VALUE="${SUITECRM_PASS:-Harbor2026}"

append_env() {
    key="$1"
    value="$2"
    if [ -f /etc/environment ]; then
        if ! grep -q "^${key}=" /etc/environment 2>/dev/null; then
            echo "${key}=${value}" >> /etc/environment
        fi
    fi
}

append_env "SUITECRM_URL" "${SUITECRM_URL_VALUE}"
append_env "SUITECRM_CLIENT_ID" "${SUITECRM_CLIENT_ID_VALUE}"
append_env "SUITECRM_CLIENT_SECRET" "${SUITECRM_CLIENT_SECRET_VALUE}"
append_env "SUITECRM_USER" "${SUITECRM_USER_VALUE}"
append_env "SUITECRM_PASS" "${SUITECRM_PASS_VALUE}"

if [ -d /etc/profile.d ]; then
    cat > /etc/profile.d/suitecrm_env.sh <<EOF
export SUITECRM_URL="${SUITECRM_URL_VALUE}"
export SUITECRM_CLIENT_ID="${SUITECRM_CLIENT_ID_VALUE}"
export SUITECRM_CLIENT_SECRET="${SUITECRM_CLIENT_SECRET_VALUE}"
export SUITECRM_USER="${SUITECRM_USER_VALUE}"
export SUITECRM_PASS="${SUITECRM_PASS_VALUE}"
EOF
    chmod 0644 /etc/profile.d/suitecrm_env.sh
fi

SRC="${SKILL_DIR}/mock_assets/reference"
DEST="${SKILL_DIR}/reference"
if [ -d "${SRC}" ] && [ -w "${SKILL_DIR}" ]; then
    mkdir -p "${DEST}"
    cp -r "${SRC}/." "${DEST}/"
fi

echo "[suitecrm-init] ready"
