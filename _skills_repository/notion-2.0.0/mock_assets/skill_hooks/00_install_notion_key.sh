#!/bin/bash
# Pre-populate the Notion API key file at ~/.config/notion/api_key so the
# SKILL.md curl commands work immediately. The DNS hijack routes
# api.notion.com traffic to the local API server, which ignores the
# Authorization header — the key value just needs to look real.

set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"
install -m 0755 "${SKILL_DIR}/mock_assets/bin/notion-state" /usr/local/bin/notion-state
RUNTIME_ROOT=/tmp/scry/mock"_api"
chmod 0666 "${RUNTIME_ROOT}/api_handlers/api_notion_com.json" 2>/dev/null || true

KEY_DIR_HOME="${HOME:-/root}/.config/notion"
KEY_FILE_HOME="${KEY_DIR_HOME}/api_key"

KEY_DIR_ROOT="/root/.config/notion"
KEY_FILE_ROOT="${KEY_DIR_ROOT}/api_key"

NOTION_KEY_VALUE="ntn_a3f8c2e1d4b7906582ac9f51e0d7b4c20695a8d3f1c6e2a9"

write_key() {
    local dir="$1"
    local file="$2"
    mkdir -p "${dir}"
    if [ ! -s "${file}" ]; then
        printf "%s" "${NOTION_KEY_VALUE}" > "${file}"
        chmod 0600 "${file}" || true
    fi
}

write_key "${KEY_DIR_HOME}" "${KEY_FILE_HOME}"
write_key "${KEY_DIR_ROOT}" "${KEY_FILE_ROOT}"

# Also expose as env var for clients that prefer it over the file.
PROFILE_LINE="export NOTION_API_KEY=\"${NOTION_KEY_VALUE}\""
for rc in /root/.bashrc /etc/profile.d/notion_api_key.sh; do
    rc_dir="$(dirname "${rc}")"
    [ -d "${rc_dir}" ] || continue
    if [ ! -f "${rc}" ] || ! grep -q "NOTION_API_KEY" "${rc}" 2>/dev/null; then
        printf "%s\n" "${PROFILE_LINE}" >> "${rc}"
    fi
done
chmod 0644 /etc/profile.d/notion_api_key.sh 2>/dev/null || true

echo "[notion-init] api_key provisioned at ${KEY_FILE_HOME}"
