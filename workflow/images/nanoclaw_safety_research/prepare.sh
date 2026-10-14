#!/bin/bash
set -euo pipefail

BUILD_DIR="$1"
PROJECT_DIR="$3"
SKILLS_REPO_DIR="${4:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../_skills_repository" && pwd)}"
IMAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_IMAGES_DIR="$(cd "${IMAGES_DIR}/../nanoclaw" && pwd)"
OVERLAY_DIR="$(cd "${IMAGES_DIR}/../safety_research_overlay" && pwd)"

if [[ -z "${BUILD_DIR}" ]]; then
    echo "[ERROR] BUILD_DIR is not specified"
    exit 1
fi

echo "[INFO] Preparing nanoclaw_safety_research image build context..."
bash "${BASE_IMAGES_DIR}/prepare.sh" "${BUILD_DIR}" "" "${PROJECT_DIR}" "${SKILLS_REPO_DIR}"
if [[ ! -s "${BUILD_DIR}/docker/openclaw.json" ]]; then
    echo "[ERROR] generated openclaw.json is missing; run scripts/generate_config.py first"
    exit 1
fi
bash "${OVERLAY_DIR}/prepare.sh" "${BUILD_DIR}" "" "${PROJECT_DIR}" "${SKILLS_REPO_DIR}"
cp "${IMAGES_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"
echo "[INFO] nanoclaw_safety_research image build context prepared"
