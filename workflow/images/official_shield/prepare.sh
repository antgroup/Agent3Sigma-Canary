#!/bin/bash
#
# ============================================================================
# official_shield image data preparation script
# ============================================================================
#
# Purpose
# Add the openclaw-shield security plugin on top of the official image context.
# Preserve the official model configuration, custom skills, skill_data, and mock-api server.
#
# Arguments
#   $1 - Build directory
#   $2 - Reserved argument (unused by this image; kept for compatibility)
#   $3 - Project directory
#   $4 - Skills source directory (defaults to official/prepare.sh behavior)
#
# Optional environment variables
#   OPENCLAW_SHIELD_SOURCE_DIR - Local pre-cloned openclaw-shield source directory
#
# ============================================================================

BUILD_DIR="$1"
PROJECT_DIR="$3"
SKILLS_REPO_DIR="$4"
IMAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICIAL_IMAGES_DIR="$(cd "${IMAGES_DIR}/../official" && pwd)"
DEFAULT_SHIELD_SOURCE_DIR="${IMAGES_DIR}/openclaw-shield"
SHIELD_SOURCE_DIR="${OPENCLAW_SHIELD_SOURCE_DIR:-${DEFAULT_SHIELD_SOURCE_DIR}}"

if [[ -z "${BUILD_DIR}" ]]; then
    echo "[ERROR] BUILD_DIR is not specified"
    exit 1
fi

echo "[INFO] Preparing official_shield image data..."
echo "  Build directory: ${BUILD_DIR}"
echo "  Project directory: ${PROJECT_DIR}"
echo "  Shield source directory: ${SHIELD_SOURCE_DIR}"

# Reuse the complete official build context, including model configuration, skills, and mock-api data.
if [[ -n "${SKILLS_REPO_DIR}" ]]; then
    bash "${OFFICIAL_IMAGES_DIR}/prepare.sh" "${BUILD_DIR}" "" "${PROJECT_DIR}" "${SKILLS_REPO_DIR}" || exit 1
else
    bash "${OFFICIAL_IMAGES_DIR}/prepare.sh" "${BUILD_DIR}" "" "${PROJECT_DIR}" || exit 1
fi

# Override the Dockerfile and OpenClaw configuration to load the openclaw-shield plugin.
cp "${IMAGES_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"
cp "${IMAGES_DIR}/openclaw.json" "${BUILD_DIR}/docker/openclaw.json"

# Use a pre-cloned openclaw-shield source directory. The build does not access GitHub.
if [[ ! -f "${SHIELD_SOURCE_DIR}/package.json" || ! -f "${SHIELD_SOURCE_DIR}/openclaw.plugin.json" || ! -d "${SHIELD_SOURCE_DIR}/src" ]]; then
    echo "[ERROR] openclaw-shield source directory is incomplete: ${SHIELD_SOURCE_DIR}"
    echo "[HINT] Clone https://github.com/knostic/openclaw-shield into this directory, or set OPENCLAW_SHIELD_SOURCE_DIR"
    exit 1
fi

mkdir -p "${BUILD_DIR}/docker/openclaw-shield"
cp "${SHIELD_SOURCE_DIR}/package.json" "${BUILD_DIR}/docker/openclaw-shield/"
cp "${SHIELD_SOURCE_DIR}/openclaw.plugin.json" "${BUILD_DIR}/docker/openclaw-shield/"
cp -r "${SHIELD_SOURCE_DIR}/src" "${BUILD_DIR}/docker/openclaw-shield/"

if [[ -f "${SHIELD_SOURCE_DIR}/README.md" ]]; then
    cp "${SHIELD_SOURCE_DIR}/README.md" "${BUILD_DIR}/docker/openclaw-shield/"
fi

if [[ -f "${SHIELD_SOURCE_DIR}/LICENSE" ]]; then
    cp "${SHIELD_SOURCE_DIR}/LICENSE" "${BUILD_DIR}/docker/openclaw-shield/"
fi

if [[ -d "${SHIELD_SOURCE_DIR}/docs" ]]; then
    cp -r "${SHIELD_SOURCE_DIR}/docs" "${BUILD_DIR}/docker/openclaw-shield/"
fi

echo "[INFO] official_shield image data preparation completed"
