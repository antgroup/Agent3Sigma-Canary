#!/bin/bash
# Build-context preparer for the claude_code (Claude Code CLI) variant image.
# Reuses safety_master's current official build context so mock-api, global
# handlers, and per-task skill mounting stay aligned with the target branch.

BUILD_DIR="$1"
PROJECT_DIR="$3"
SKILLS_REPO_DIR="${4:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../_skills_repository" && pwd)}"
IMAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICIAL_IMAGES_DIR="$(cd "${IMAGES_DIR}/../official" && pwd)"

if [[ -z "${BUILD_DIR}" ]]; then
    echo "[ERROR] BUILD_DIR is not specified"
    exit 1
fi

echo "[INFO] Preparing claude_code image build context..."

if [[ -n "${SKILLS_REPO_DIR}" ]]; then
    bash "${OFFICIAL_IMAGES_DIR}/prepare.sh" "${BUILD_DIR}" "" "${PROJECT_DIR}" "${SKILLS_REPO_DIR}" || exit 1
else
    bash "${OFFICIAL_IMAGES_DIR}/prepare.sh" "${BUILD_DIR}" "" "${PROJECT_DIR}" || exit 1
fi

if [[ ! -s "${BUILD_DIR}/docker/openclaw.json" ]]; then
    echo "[ERROR] generated openclaw.json is missing; run scripts/generate_config.py first"
    exit 1
fi

mkdir -p "${BUILD_DIR}/shim"
cp "${IMAGES_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"
cp "${IMAGES_DIR}/shim/openclaw" "${BUILD_DIR}/shim/openclaw"
chmod +x "${BUILD_DIR}/shim/openclaw"

echo "[INFO] claude_code image build context prepared"
