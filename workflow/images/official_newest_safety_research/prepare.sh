#!/bin/bash
# Prepare the official safety-research context, then replace only its
# Dockerfile with the variant pinned to the latest verified OpenClaw release.

BUILD_DIR="$1"
PROJECT_DIR="$3"
SKILLS_REPO_DIR="${4:-}"
IMAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_IMAGE_DIR="$(cd "${IMAGES_DIR}/../official_safety_research" && pwd)"

if [[ -z "${BUILD_DIR}" ]]; then
    echo "[ERROR] BUILD_DIR is not specified"
    exit 1
fi

echo "[INFO] Preparing official_newest_safety_research image data..."
bash "${BASE_IMAGE_DIR}/prepare.sh" \
    "${BUILD_DIR}" "" "${PROJECT_DIR}" "${SKILLS_REPO_DIR}" || exit 1
cp "${IMAGES_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"
echo "[INFO] official_newest_safety_research image data preparation completed"
