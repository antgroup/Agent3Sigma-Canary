#!/bin/bash
#
# ============================================================================
# Official image data preparation script
# ============================================================================
#
# Purpose
# Prepare data files required to build the official image.
# Includes native OpenClaw, custom skills, and mock-api server data.
#
# Arguments
#   $1 - Build directory
#   $2 - Reserved argument (unused by this image; kept for compatibility)
#   $3 - Project directory
#   $4 - Skills source directory (default: ../../../_skills_repository)
#
# ============================================================================

BUILD_DIR="$1"
PROJECT_DIR="$3"
SKILLS_REPO_DIR="${4:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../_skills_repository" && pwd)}"
SKILL_DEST_DIR="${SKILLS_REPO_DIR}/../_skills_repository/skill_dest"
IMAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${BUILD_DIR}" ]]; then
    echo "[ERROR] BUILD_DIR is not specified"
    exit 1
fi

echo "[INFO] Preparing official image data..."
echo "  Build directory: ${BUILD_DIR}"
echo "  Project directory: ${PROJECT_DIR}"
echo "  Skills source directory: ${SKILLS_REPO_DIR}"
echo "  Packaged skills directory: ${SKILL_DEST_DIR}"

# Create the directory layout.
# Skills and skill_data are NOT staged here anymore — they are bind-mounted /
# docker-cp'd per task at run time by scripts/lib_docker.py + lib_agent.py.
mkdir -p "${BUILD_DIR}/docker/mock-api"
mkdir -p "${BUILD_DIR}/docker/mock_api_data"

# Copy the OpenClaw configuration file.
cp "${IMAGES_DIR}/openclaw.json" "${BUILD_DIR}/docker/openclaw.json"

# Copy the mock-api directory.
if [[ -d "${IMAGES_DIR}/mock-api" ]]; then
    echo "  Copying mock-api directory..."
    cp -r "${IMAGES_DIR}/mock-api/"* "${BUILD_DIR}/docker/mock-api/"
else
    echo "[ERROR] mock-api directory does not exist: ${IMAGES_DIR}/mock-api"
    exit 1
fi

# Copy the Dockerfile.
cp "${IMAGES_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"

# Copy assets/mock_api/data into the build directory (task-agnostic; bakes in).
ASSETS_MOCK_API_DATA="${PROJECT_DIR}/assets/mock_api/data"
if [[ -d "${ASSETS_MOCK_API_DATA}" ]]; then
    echo "  Copying assets/mock_api/data..."
    cp -r "${ASSETS_MOCK_API_DATA}/"* "${BUILD_DIR}/docker/mock_api_data/"
else
    echo "[WARN] assets/mock_api/data directory does not exist: ${ASSETS_MOCK_API_DATA}"
fi

# Note: per-skill mock_api/api_handlers/*.json and skill_hooks/*.sh are
# no longer staged here. They live inside each skill's mock_assets/
# directory (preserved by buildAll.sh) and are collected at runtime by
# /opt/mock-api/entrypoint.sh:collect_skill_mock_assets().

# Copy global API handlers that are not tied to a skill. These are pre-seeded
# into HANDLERS_DIR alongside per-skill handlers collected at runtime.
ASSETS_API_HANDLERS="${PROJECT_DIR}/assets/mock_api/api_handlers"
mkdir -p "${BUILD_DIR}/docker/mock_api_handlers"
if [[ -d "${ASSETS_API_HANDLERS}" ]] && ls "${ASSETS_API_HANDLERS}"/*.json &>/dev/null; then
    cp "${ASSETS_API_HANDLERS}"/*.json "${BUILD_DIR}/docker/mock_api_handlers/"
    echo "  Copied $(ls "${BUILD_DIR}/docker/mock_api_handlers/"*.json | wc -l) global api_handler(s)"
fi

echo "[INFO] official image data preparation completed"
