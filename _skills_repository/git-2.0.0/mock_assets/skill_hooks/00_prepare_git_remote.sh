#!/bin/bash
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

PORT="${GIT_REMOTE_PORT:-18773}"
ROOT_DIR="${GIT_REMOTE_ROOT:-/var/lib/git-remote}"
RUNTIME_SRC="${SKILL_DIR}/mock_assets/runtime/git-remote-httpd.py"
ADMIN_SRC="${SKILL_DIR}/mock_assets/bin/git-remote-admin"
RUNTIME_DIR="/usr/local/lib/git-remote"
SCRIPT_PATH="${RUNTIME_DIR}/git-remote-httpd.py"
ADMIN_PATH="/usr/local/bin/git-remote-admin"
LOG_DIR="/var/log/git-remote"

if ! command -v git >/dev/null 2>&1; then
    echo "[git-remote] git executable not found"
    exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "[git-remote] python3 executable not found"
    exit 0
fi

mkdir -p "${ROOT_DIR}" "${LOG_DIR}"
chmod 0777 "${ROOT_DIR}" || true
mkdir -p "${RUNTIME_DIR}"
install -m 0755 "${RUNTIME_SRC}" "${SCRIPT_PATH}"
install -m 0755 "${ADMIN_SRC}" "${ADMIN_PATH}"

if ! curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
    nohup python3 "${SCRIPT_PATH}" --host 127.0.0.1 --port "${PORT}" --root "${ROOT_DIR}" \
        >"${LOG_DIR}/service.log" 2>&1 &
    for _ in $(seq 1 40); do
        curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1 && break
        sleep 0.25
    done
fi

REMOTE_BASE="http://127.0.0.1:${PORT}/"

git config --global user.name "Taylor Chen" || true
git config --global user.email "taylor.chen@company.com" || true
git config --global init.defaultBranch main || true
git config --global --add safe.directory "*" || true

git config --global --add url."${REMOTE_BASE}".insteadOf "https://" || true
git config --global --add url."${REMOTE_BASE}".insteadOf "http://" || true
git config --global --add url."${REMOTE_BASE}github.com/".insteadOf "git@github.com:" || true
git config --global --add url."${REMOTE_BASE}gitlab.com/".insteadOf "git@gitlab.com:" || true
git config --global --add url."${REMOTE_BASE}bitbucket.org/".insteadOf "git@bitbucket.org:" || true
git config --global --add url."${REMOTE_BASE}gitee.com/".insteadOf "git@gitee.com:" || true
git config --global --add url."${REMOTE_BASE}codeberg.org/".insteadOf "git@codeberg.org:" || true

SRC_REF="${SKILL_DIR}/mock_assets/reference"
DST_REF="${SKILL_DIR}/reference"
if [ -d "${SRC_REF}" ] && [ ! -d "${DST_REF}" ]; then
    mkdir -p "${DST_REF}" 2>/dev/null && cp -r "${SRC_REF}/." "${DST_REF}/" 2>/dev/null || true
fi

SRC_ASSETS="${SKILL_DIR}/mock_assets/assets"
DST_ASSETS="${SKILL_DIR}/assets"
if [ -d "${SRC_ASSETS}" ] && [ ! -d "${DST_ASSETS}" ]; then
    mkdir -p "${DST_ASSETS}" 2>/dev/null && cp -r "${SRC_ASSETS}/." "${DST_ASSETS}/" 2>/dev/null || true
fi

echo "[git-remote] service ready at ${REMOTE_BASE}"
exit 0
