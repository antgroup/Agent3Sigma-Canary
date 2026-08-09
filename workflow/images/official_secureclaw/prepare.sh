#!/bin/bash
#
# ============================================================================
# official_secureclaw image data preparation script
# ============================================================================
#
# Purpose
# Add the SecureClaw security plugin on top of the official image context.
# Preserve the official model configuration, custom skills, skill_data, and mock-api server.
#
# Arguments
#   $1 - Build directory
#   $2 - Reserved argument (unused by this image; kept for compatibility)
#   $3 - Project directory
#   $4 - Skills source directory (defaults to official/prepare.sh behavior)
#
# Optional environment variables
#   SECURECLAW_SOURCE_DIR - Local pre-cloned secureclaw repository directory
#
# ============================================================================

BUILD_DIR="$1"
PROJECT_DIR="$3"
SKILLS_REPO_DIR="$4"
IMAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICIAL_IMAGES_DIR="$(cd "${IMAGES_DIR}/../official" && pwd)"
DEFAULT_SECURECLAW_SOURCE_DIR="${IMAGES_DIR}/secureclaw"
SECURECLAW_SOURCE_DIR="${SECURECLAW_SOURCE_DIR:-${DEFAULT_SECURECLAW_SOURCE_DIR}}"
SECURECLAW_PACKAGE_DIR="${SECURECLAW_SOURCE_DIR}/secureclaw"

if [[ -z "${BUILD_DIR}" ]]; then
    echo "[ERROR] BUILD_DIR is not specified"
    exit 1
fi

echo "[INFO] Preparing official_secureclaw image data..."
echo "  Build directory: ${BUILD_DIR}"
echo "  Project directory: ${PROJECT_DIR}"
echo "  SecureClaw source directory: ${SECURECLAW_SOURCE_DIR}"

# Reuse the complete official build context, including model configuration, skills, and mock-api data.
if [[ -n "${SKILLS_REPO_DIR}" ]]; then
    bash "${OFFICIAL_IMAGES_DIR}/prepare.sh" "${BUILD_DIR}" "" "${PROJECT_DIR}" "${SKILLS_REPO_DIR}" || exit 1
else
    bash "${OFFICIAL_IMAGES_DIR}/prepare.sh" "${BUILD_DIR}" "" "${PROJECT_DIR}" || exit 1
fi

# Override the Dockerfile and OpenClaw configuration to install the SecureClaw plugin.
cp "${IMAGES_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"
cp "${IMAGES_DIR}/openclaw.json" "${BUILD_DIR}/docker/openclaw.json"

# Use a pre-cloned SecureClaw source directory. The build does not access GitHub.
if [[ ! -f "${SECURECLAW_PACKAGE_DIR}/package.json" || ! -f "${SECURECLAW_PACKAGE_DIR}/openclaw.plugin.json" || ! -d "${SECURECLAW_PACKAGE_DIR}/src" ]]; then
    echo "[ERROR] SecureClaw source directory is incomplete: ${SECURECLAW_SOURCE_DIR}"
    echo "[HINT] Clone https://github.com/adversa-ai/secureclaw into this directory, or set SECURECLAW_SOURCE_DIR"
    exit 1
fi

mkdir -p "${BUILD_DIR}/docker/secureclaw"
cp -R "${SECURECLAW_SOURCE_DIR}/." "${BUILD_DIR}/docker/secureclaw/"
rm -rf "${BUILD_DIR}/docker/secureclaw/.git"

echo "[INFO] official_secureclaw image data preparation completed"
