#!/bin/bash
BUILD_DIR="$1"
PROJECT_DIR="$3"
SKILLS_REPO_DIR="${4:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../_skills_repository" && pwd)}"
SKILL_DEST_DIR="${SKILLS_REPO_DIR}/../_skills_repository/skill_dest"
IMAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -z "${BUILD_DIR}" ]] && { echo "[ERROR] BUILD_DIR not set"; exit 1; }

mkdir -p "${BUILD_DIR}/docker/skills" "${BUILD_DIR}/docker/skill_data" \
         "${BUILD_DIR}/docker/mock-api" "${BUILD_DIR}/docker/mock_api_data" \
         "${BUILD_DIR}/shim"

[[ -d "${SKILL_DEST_DIR}/skills" ]] || { echo "[ERROR] skills not built"; exit 1; }
cp -r "${SKILL_DEST_DIR}/skills/"* "${BUILD_DIR}/docker/skills/"

cp "${IMAGES_DIR}/openclaw.json" "${BUILD_DIR}/docker/openclaw.json"
cp -r "${IMAGES_DIR}/mock-api/"* "${BUILD_DIR}/docker/mock-api/"
cp "${IMAGES_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"
cp "${IMAGES_DIR}/shim/openclaw"          "${BUILD_DIR}/shim/openclaw"
cp "${IMAGES_DIR}/shim/driver.mjs"        "${BUILD_DIR}/shim/driver.mjs"
cp "${IMAGES_DIR}/shim/driver_openai.mjs" "${BUILD_DIR}/shim/driver_openai.mjs"
chmod +x "${BUILD_DIR}/shim/openclaw"

[[ -d "${PROJECT_DIR}/assets/skill_data" ]] && cp -r "${PROJECT_DIR}/assets/skill_data/"* "${BUILD_DIR}/docker/skill_data/"
[[ -d "${PROJECT_DIR}/assets/mock_api/data" ]] && cp -r "${PROJECT_DIR}/assets/mock_api/data/"* "${BUILD_DIR}/docker/mock_api_data/"

echo "[INFO] nanoclaw_openai build context prepared"
