#!/bin/bash

# buildAll.sh - Package all skills and copy them to the target directory
# Usage: ./buildAll.sh [--platform linux|mac|all] [--proxy URL] [target directory]
# Default platform: linux
# If no target directory is specified, use ../_skills_repository/skill_dest by default

set -e

usage() {
    echo "Usage: ./buildAll.sh [--platform linux|mac|all] [--proxy URL] [target directory]"
    echo ""
    echo "Options:"
    echo "  --platform VALUE  Build skill binaries for linux, mac, or all. Default: linux"
    echo "  --proxy URL       Use HTTP proxy for Docker builds"
    echo "                    On macOS/Windows Docker Desktop, the URL is auto-rewritten to http://host.docker.internal:<port>"
    echo "                    On Linux, --network host is added to Docker build commands"
    echo "  -h, --help        Show this help message"
}

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REPO_DIR="${SCRIPT_DIR}"

PLATFORM="linux"
SKILL_DEST=""
DOCKER_PROXY_ENABLED=false
DOCKER_PROXY_URL=""
DOCKER_EXTRA_BUILD_ARGS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --platform)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --platform requires a value"
                usage
                exit 1
            fi
            PLATFORM="$2"
            shift 2
            ;;
        --platform=*)
            PLATFORM="${1#*=}"
            shift
            ;;
        --proxy)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --proxy requires a URL"
                usage
                exit 1
            fi
            DOCKER_PROXY_ENABLED=true
            DOCKER_PROXY_URL="$2"
            shift 2
            ;;
        --proxy=*)
            DOCKER_PROXY_ENABLED=true
            DOCKER_PROXY_URL="${1#*=}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "Error: unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [[ -n "${SKILL_DEST}" ]]; then
                echo "Error: multiple target directories specified: ${SKILL_DEST} and $1"
                usage
                exit 1
            fi
            SKILL_DEST="$1"
            shift
            ;;
    esac
done

PLATFORM="$(echo "${PLATFORM}" | tr '[:upper:]' '[:lower:]')"
BUILD_MAC=false
BUILD_LINUX=false

case "${PLATFORM}" in
    linux)
        BUILD_LINUX=true
        ;;
    mac|macos|darwin)
        PLATFORM="mac"
        BUILD_MAC=true
        ;;
    all|both)
        PLATFORM="all"
        BUILD_MAC=true
        BUILD_LINUX=true
        ;;
    *)
        echo "Error: unsupported platform: ${PLATFORM}"
        usage
        exit 1
        ;;
esac

if [[ "${DOCKER_PROXY_ENABLED}" == "true" ]]; then
    if [[ -z "${DOCKER_PROXY_URL}" ]]; then
        echo "Error: --proxy requires a URL"
        usage
        exit 1
    fi

    OS_TYPE="$(uname -s)"
    if [[ "${OS_TYPE}" == "Darwin" || "${OS_TYPE}" == MINGW* || "${OS_TYPE}" == MSYS* || "${OS_TYPE}" == CYGWIN* ]]; then
        # macOS and Windows Docker Desktop builds need to reach the host through host.docker.internal.
        PROXY_PORT=$(echo "${DOCKER_PROXY_URL}" | grep -oE '[0-9]+$')
        if [[ -z "${PROXY_PORT}" ]]; then
            echo "Error: unable to extract proxy port from URL: ${DOCKER_PROXY_URL}"
            exit 1
        fi
        DOCKER_PROXY_URL="http://host.docker.internal:${PROXY_PORT}"
        DOCKER_EXTRA_BUILD_ARGS=""
    else
        # Linux Docker builds can reach localhost proxies through host networking.
        DOCKER_EXTRA_BUILD_ARGS="--network host"
    fi
fi

export DOCKER_PROXY_ENABLED
export DOCKER_PROXY_URL
export DOCKER_EXTRA_BUILD_ARGS

# Target directory: prefer the argument, otherwise use the default
if [[ -z "${SKILL_DEST}" ]]; then
    SKILL_DEST="${SKILLS_REPO_DIR}/../_skills_repository/skill_dest"
fi

# Ensure the target directory is an absolute path
SKILL_DEST="$(cd "$(dirname "${SKILL_DEST}")" 2>/dev/null && pwd)/$(basename "${SKILL_DEST}")" || {
    # If the directory does not exist, create its parents
    mkdir -p "${SKILL_DEST}"
    SKILL_DEST="$(cd "${SKILL_DEST}" && pwd)"
}

echo "=========================================="
echo "Packaging skills..."
echo "Source directory: ${SKILLS_REPO_DIR}"
echo "Target directory: ${SKILL_DEST}"
echo "Platform: ${PLATFORM}"
if [[ "${DOCKER_PROXY_ENABLED}" == "true" ]]; then
    echo "Docker proxy: ${DOCKER_PROXY_URL}"
else
    echo "Docker proxy: disabled"
fi
echo "=========================================="

# Create target directories
mkdir -p "${SKILL_DEST}/skills"
mkdir -p "${SKILL_DEST}/skill_data"

# Iterate over all skill directories
skill_count=0
for skill_dir in "${SKILLS_REPO_DIR}"/*/; do
    # Skip non-directories
    if [[ ! -d "${skill_dir}" ]]; then
        continue
    fi

    skill_name=$(basename "${skill_dir}")

    # Skip non-skill directories such as __pycache__
    if [[ "${skill_name}" == "__pycache__" ]] || [[ "${skill_name}" == .* ]]; then
        continue
    fi

    # Check whether this is a valid skill directory with SKILL.md or skill.md
    if [[ ! -f "${skill_dir}SKILL.md" ]] && [[ ! -f "${skill_dir}skill.md" ]]; then
        echo "  Skipping non-skill directory: ${skill_name}"
        continue
    fi

    echo ""
    echo "Processing skill: ${skill_name}"
    skill_count=$((skill_count + 1))

    # Run build scripts for the selected platform(s).
    build_mac="${skill_dir}build_mac.sh"
    build_linux="${skill_dir}build_linux.sh"

    if [[ "${BUILD_MAC}" == "true" ]]; then
        if [[ -f "${build_mac}" ]]; then
            echo "  Running build script: $(basename "${build_mac}")"
            (cd "${skill_dir}" && bash "$(basename "${build_mac}")")
        else
            echo "  Warning: build script not found: ${build_mac}"
        fi
    fi

    if [[ "${BUILD_LINUX}" == "true" ]]; then
        if [[ -f "${build_linux}" ]]; then
            echo "  Running build script: $(basename "${build_linux}")"
            (cd "${skill_dir}" && bash "$(basename "${build_linux}")")
        else
            echo "  Warning: build script not found: ${build_linux}"
        fi
    fi

    # Create target skill directory
    dest_skill_dir="${SKILL_DEST}/skills/${skill_name}"
    mkdir -p "${dest_skill_dir}"

    # Copy skill directory contents
    echo "  Copying files..."
    cp -r "${skill_dir}"* "${dest_skill_dir}/"

    # Extract the data directory into skill_data before cleanup
    # Use -E for extended regular expressions in macOS BSD sed
    skill_name_no_version=$(echo "${skill_name}" | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+$//')
    if [[ -d "${dest_skill_dir}/data" ]]; then
        echo "  Extracting data -> skill_data/${skill_name_no_version}/data/"
        mkdir -p "${SKILL_DEST}/skill_data/${skill_name_no_version}/data/"
        cp -r "${dest_skill_dir}/data/"* "${SKILL_DEST}/skill_data/${skill_name_no_version}/data/"
    fi

    # Clean generated files from the skill directory and keep only required files
    echo "  Cleaning generated files..."
    for item in "${dest_skill_dir}/"*; do
        if [[ ! -e "${item}" ]]; then
            continue
        fi

        item_name=$(basename "${item}")

        # Decide whether to keep this item
        keep=false

        # Keep directory: scripts. config is hardcoded in main.py and no longer needed.
        # Also keep mock_assets/ — used by mock-api entrypoint to load this
        # skill's API route handlers (api_handlers/*.json) and run its
        # install hooks (skill_hooks/*.sh) at container startup.
        if [[ -d "${item}" ]]; then
            if [[ "${item_name}" == "scripts" ]]; then
                keep=true
            elif [[ "${item_name}" == "mock_assets" ]]; then
                keep=true
            fi
        # Keep file: SKILL.md, case-insensitive
        elif [[ "$(echo "${item_name}" | tr '[:upper:]' '[:lower:]')" == "skill.md" ]]; then
            keep=true
        # Keep executable binaries, excluding script files such as .sh or .py
        elif [[ -x "${item}" ]]; then
            # Exclude script files and hidden files
            case "${item_name}" in
                *.sh|*.py|*.rb|*.pl|*.lua) ;;
                .*) ;;
                *_mac) [[ "${BUILD_MAC}" == "true" ]] && keep=true ;;
                *_linux) [[ "${BUILD_LINUX}" == "true" ]] && keep=true ;;
                *) keep=true ;;
            esac
        fi

        # Remove files/directories that should not be kept
        if [[ "${keep}" == "false" ]]; then
            rm -rf "${item}"
        fi
    done

    # Remove hidden files such as .DS_Store
    find "${dest_skill_dir}" -maxdepth 1 -name ".*" -type f -delete 2>/dev/null || true

    # Pre-restore reference docs on host. The skill-to-sandbox "reference docs"
    # pattern ships docs under mock_assets/reference/ and adds a startup hook
    # that copies them to <skill>/reference/. The runner bind-mounts the skill
    # :ro, so the hook can't write — do the restore here instead.
    if [[ -d "${dest_skill_dir}/mock_assets/reference" ]]; then
        echo "  Pre-restoring reference docs to ${skill_name}/reference/"
        mkdir -p "${dest_skill_dir}/reference"
        cp -r "${dest_skill_dir}/mock_assets/reference/." "${dest_skill_dir}/reference/"
    fi

    echo "  Done: ${skill_name}"
done

echo ""
echo "=========================================="
echo "Packaging complete!"
echo "Processed ${skill_count} skills"
echo "Target directory: ${SKILL_DEST}"
echo "Platform: ${PLATFORM}"
echo "  - skills/     : packaged skill directories"
echo "  - skill_data/ : extracted data directories"
echo "=========================================="

# Copy skill_data into the assets directory
ASSETS_DIR="${SKILLS_REPO_DIR}/../assets"
if [[ -d "${SKILL_DEST}/skill_data" ]]; then
    echo ""
    echo "Copying skill_data to assets directory..."
    mkdir -p "${ASSETS_DIR}"
    rm -rf "${ASSETS_DIR}/skill_data"
    cp -r "${SKILL_DEST}/skill_data" "${ASSETS_DIR}/"
    echo "  Copied to: ${ASSETS_DIR}/skill_data"
fi
