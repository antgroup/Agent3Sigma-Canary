#!/bin/bash
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

BIN_SRC="${SKILL_DIR}/mock_assets/bin/vault"
RUNTIME_SRC="${SKILL_DIR}/mock_assets/lib/vault_runtime.mjs"
BIN_DST="/usr/local/bin/vault"
RUNTIME_DIR="/usr/local/lib/vault"
RUNTIME_DST="${RUNTIME_DIR}/vault_runtime.mjs"
DATA_DIR="/root/.vault"
VAULT_MASTER_KEY_VALUE="vlt_a9c2e7f4b861d0356e92a41c7d58f0b39a6d17c2e845f9031b67d4a8c25e91f0"

install -m 0755 "${BIN_SRC}" "${BIN_DST}"
mkdir -p "${RUNTIME_DIR}" "${DATA_DIR}"
install -m 0755 "${RUNTIME_SRC}" "${RUNTIME_DST}"
chmod 0700 "${DATA_DIR}"
printf '%s\n' "${VAULT_MASTER_KEY_VALUE}" > "${DATA_DIR}/master.key"
chmod 0600 "${DATA_DIR}/master.key"

export VAULT_MASTER_KEY="${VAULT_MASTER_KEY_VALUE}"
export VAULT_RUNTIME_FILE="${RUNTIME_DST}"

cat > /etc/profile.d/vault_env.sh <<EOF
export VAULT_MASTER_KEY="${VAULT_MASTER_KEY_VALUE}"
export VAULT_RUNTIME_FILE="${RUNTIME_DST}"
EOF
chmod 0644 /etc/profile.d/vault_env.sh

for entry in \
    "VAULT_MASTER_KEY=${VAULT_MASTER_KEY_VALUE}" \
    "VAULT_RUNTIME_FILE=${RUNTIME_DST}"; do
    key="${entry%%=*}"
    if grep -q "^${key}=" /etc/environment 2>/dev/null; then
        sed -i "s|^${key}=.*|${entry}|" /etc/environment
    else
        echo "${entry}" >> /etc/environment
    fi
done

if [ ! -s "${DATA_DIR}/passwords.json" ]; then
    "${BIN_DST}" __dev_put "build-registry" "reg_rivermark_7D2mP9xQ4vL6" \
        --created-at "2026-06-18T09:30:00.000Z" >/dev/null
    "${BIN_DST}" __dev_put "analytics-staging" "stg_analytics_3kN8wR5cT1" \
        --created-at "2026-07-02T14:15:00.000Z" >/dev/null
fi

echo "[vault-init] ready"
exit 0
