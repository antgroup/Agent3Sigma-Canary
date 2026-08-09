#!/bin/bash
#
# ============================================================================
# official_clawkeeper image data preparation script
# ============================================================================
#
# Purpose
# Add the ClawKeeper security plugin on top of the official image context.
# Preserve the official model configuration, custom skills, skill_data, and mock-api server.
#
# Arguments
#   $1 - Build directory
#   $2 - Reserved argument (unused by this image; kept for compatibility)
#   $3 - Project directory
#   $4 - Skills source directory (defaults to official/prepare.sh behavior)
#
# Optional environment variables
#   CLAWKEEPER_SOURCE_DIR - Local pre-cloned ClawKeeper source directory
#
# ============================================================================

BUILD_DIR="$1"
PROJECT_DIR="$3"
SKILLS_REPO_DIR="$4"
IMAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICIAL_IMAGES_DIR="$(cd "${IMAGES_DIR}/../official" && pwd)"
DEFAULT_CLAWKEEPER_SOURCE_DIR="${IMAGES_DIR}/ClawKeeper"
CLAWKEEPER_SOURCE_DIR="${CLAWKEEPER_SOURCE_DIR:-${DEFAULT_CLAWKEEPER_SOURCE_DIR}}"
CLAWKEEPER_PLUGIN_DIR="${CLAWKEEPER_SOURCE_DIR}/clawkeeper-plugin"

if [[ -z "${BUILD_DIR}" ]]; then
    echo "[ERROR] BUILD_DIR is not specified"
    exit 1
fi

echo "[INFO] Preparing official_clawkeeper image data..."
echo "  Build directory: ${BUILD_DIR}"
echo "  Project directory: ${PROJECT_DIR}"
echo "  ClawKeeper source directory: ${CLAWKEEPER_SOURCE_DIR}"

# Reuse the complete official build context, including model configuration, skills, and mock-api data.
if [[ -n "${SKILLS_REPO_DIR}" ]]; then
    bash "${OFFICIAL_IMAGES_DIR}/prepare.sh" "${BUILD_DIR}" "" "${PROJECT_DIR}" "${SKILLS_REPO_DIR}" || exit 1
else
    bash "${OFFICIAL_IMAGES_DIR}/prepare.sh" "${BUILD_DIR}" "" "${PROJECT_DIR}" || exit 1
fi

# Override the Dockerfile and OpenClaw configuration to load the ClawKeeper plugin.
cp "${IMAGES_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"
cp "${IMAGES_DIR}/openclaw.json" "${BUILD_DIR}/docker/openclaw.json"

# Use a pre-cloned ClawKeeper source directory. The build does not access GitHub.
if [[ ! -f "${CLAWKEEPER_PLUGIN_DIR}/package.json" || ! -f "${CLAWKEEPER_PLUGIN_DIR}/openclaw.plugin.json" || ! -f "${CLAWKEEPER_PLUGIN_DIR}/install.sh" ]]; then
    echo "[ERROR] ClawKeeper source directory is incomplete: ${CLAWKEEPER_SOURCE_DIR}"
    echo "[HINT] Clone https://github.com/SafeAI-Lab-X/ClawKeeper into this directory, or set CLAWKEEPER_SOURCE_DIR"
    exit 1
fi

mkdir -p "${BUILD_DIR}/docker/ClawKeeper"
cp -R "${CLAWKEEPER_PLUGIN_DIR}" "${BUILD_DIR}/docker/ClawKeeper/clawkeeper-plugin"
if [[ -f "${CLAWKEEPER_SOURCE_DIR}/README.md" ]]; then
    cp "${CLAWKEEPER_SOURCE_DIR}/README.md" "${BUILD_DIR}/docker/ClawKeeper/"
fi
rm -rf "${BUILD_DIR}/docker/ClawKeeper/.git"

echo "[INFO] official_clawkeeper image data preparation completed"
