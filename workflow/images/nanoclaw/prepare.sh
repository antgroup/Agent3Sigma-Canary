#!/bin/bash
# Build-context preparer for the nanoclaw variant image.

BUILD_DIR="$1"
PROJECT_DIR="$3"
SKILLS_REPO_DIR="${4:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../_skills_repository" && pwd)}"
SKILL_DEST_DIR="${SKILLS_REPO_DIR}/../_skills_repository/skill_dest"
IMAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${BUILD_DIR}" ]]; then
    echo "[ERROR] BUILD_DIR is not specified"
    exit 1
fi

echo "[INFO] Preparing nanoclaw image build context..."

mkdir -p "${BUILD_DIR}/docker/skills"
mkdir -p "${BUILD_DIR}/docker/skill_data"
mkdir -p "${BUILD_DIR}/docker/mock-api"
mkdir -p "${BUILD_DIR}/docker/mock_api_data"
mkdir -p "${BUILD_DIR}/shim"

if [[ -d "${SKILL_DEST_DIR}/skills" ]]; then
    cp -r "${SKILL_DEST_DIR}/skills/"* "${BUILD_DIR}/docker/skills/"
else
    echo "[ERROR] ${SKILL_DEST_DIR}/skills does not exist (run _skills_repository/buildAll.sh first)"
    exit 1
fi

cp "${IMAGES_DIR}/openclaw.json" "${BUILD_DIR}/docker/openclaw.json"
cp -r "${IMAGES_DIR}/mock-api/"* "${BUILD_DIR}/docker/mock-api/"
cp "${IMAGES_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"
cp "${IMAGES_DIR}/shim/openclaw" "${BUILD_DIR}/shim/openclaw"
cp "${IMAGES_DIR}/shim/driver.mjs" "${BUILD_DIR}/shim/driver.mjs"
chmod +x "${BUILD_DIR}/shim/openclaw"

ASSETS_SKILL_DATA="${PROJECT_DIR}/assets/skill_data"
if [[ -d "${ASSETS_SKILL_DATA}" ]]; then
    cp -r "${ASSETS_SKILL_DATA}/"* "${BUILD_DIR}/docker/skill_data/"
fi

ASSETS_MOCK_API_DATA="${PROJECT_DIR}/assets/mock_api/data"
if [[ -d "${ASSETS_MOCK_API_DATA}" ]]; then
    cp -r "${ASSETS_MOCK_API_DATA}/"* "${BUILD_DIR}/docker/mock_api_data/"
fi

echo "[INFO] nanoclaw image build context prepared"
