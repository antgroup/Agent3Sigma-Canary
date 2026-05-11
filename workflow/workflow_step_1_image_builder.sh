#!/usr/bin/env bash
#
# ============================================================================
# AgentCanary Docker Image Builder
# ============================================================================
#
# Builds OpenClaw benchmark Docker images:
#   - official: Base OpenClaw + custom skills + mock-api server
#   - offical_shield: official + openclaw-shield security plugin
#   - offical_secureclaw: official + SecureClaw security plugin
#   - offical_clawkeeper: official + ClawKeeper security plugin
#
# Usage:
#   bash workflow/workflow_step_1_image_builder.sh [--proxy URL]
#
# Options:
#   --proxy URL   Use HTTP proxy for Docker build (e.g. --proxy "http://127.0.0.1:7890")
#                 On macOS/Windows Docker Desktop, the URL is auto-rewritten to http://host.docker.internal:<port>
#                 On Linux, --network host is added to the build command
#
# Prerequisites:
#   - Run from AgentCanary project root
#   - Docker installed
#
# Directory structure:
#   workflow/images/
#   ├── official/             # Base image config
#   │   ├── Dockerfile
#   │   ├── openclaw.json
#   │   └── prepare.sh
#   └── offical_*/            # Security plugin variants
#       ├── Dockerfile
#       ├── openclaw.json
#       └── prepare.sh
#
# Supports resuming interrupted builds.
#
# ============================================================================

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACES_DIR="${PROJECT_DIR}/.workspaces"
IMAGES_DIR="${SCRIPT_DIR}/images"

IMAGE_TYPES=("official" "offical_shield" "offical_secureclaw" "offical_clawkeeper")

DOCKER_PROXY_ENABLED=false
DOCKER_PROXY_URL=""
DOCKER_EXTRA_BUILD_ARGS=""

STATE_FILE=""
WORK_DIR=""
TIMESTAMP=""
SELECTED_TYPES=()

# ============================================================================
# Parse arguments
# ============================================================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --proxy)
            DOCKER_PROXY_ENABLED=true
            DOCKER_PROXY_URL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: bash workflow/workflow_step_1_image_builder.sh [--proxy URL]"
            exit 1
            ;;
    esac
done

# Adapt proxy for platform
if [[ "${DOCKER_PROXY_ENABLED}" == "true" ]]; then
    if [[ -z "${DOCKER_PROXY_URL}" ]]; then
        echo "[ERROR] --proxy requires a URL argument"
        exit 1
    fi

    OS_TYPE="$(uname -s)"
    if [[ "${OS_TYPE}" == "Darwin" || "${OS_TYPE}" == MINGW* || "${OS_TYPE}" == MSYS* || "${OS_TYPE}" == CYGWIN* ]]; then
        # macOS and Windows Docker Desktop: rewrite host to host.docker.internal.
        PROXY_PORT=$(echo "${DOCKER_PROXY_URL}" | grep -oE '[0-9]+$')
        if [[ -z "${PROXY_PORT}" ]]; then
            echo "[ERROR] Unable to extract proxy port from URL: ${DOCKER_PROXY_URL}"
            exit 1
        fi
        DOCKER_PROXY_URL="http://host.docker.internal:${PROXY_PORT}"
        DOCKER_EXTRA_BUILD_ARGS=""
    else
        # Linux: use --network host so container can reach localhost proxy
        DOCKER_EXTRA_BUILD_ARGS="--network host"
    fi
fi

# ============================================================================
# Helper functions
# ============================================================================

log_info() {
    printf "[INFO] %s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

log_success() {
    printf "\033[32m[SUCCESS]\033[0m %s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

log_error() {
    printf "\033[31m[ERROR]\033[0m %s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >&2
}

log_warn() {
    printf "\033[33m[WARN]\033[0m %s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Command not found: $1. Please install it first."
        exit 1
    fi
}

save_state() {
    local step=$1
    echo "STEP=${step}" > "${STATE_FILE}"
    echo "WORK_DIR=${WORK_DIR}" >> "${STATE_FILE}"
    echo "TIMESTAMP=${TIMESTAMP}" >> "${STATE_FILE}"
    echo "DOCKER_PROXY_ENABLED=${DOCKER_PROXY_ENABLED}" >> "${STATE_FILE}"
    echo "DOCKER_PROXY_URL=${DOCKER_PROXY_URL}" >> "${STATE_FILE}"
    echo "DOCKER_EXTRA_BUILD_ARGS=\"${DOCKER_EXTRA_BUILD_ARGS}\"" >> "${STATE_FILE}"
    echo "SELECTED_TYPES_STR=\"${SELECTED_TYPES[*]}\"" >> "${STATE_FILE}"
    log_info "State saved: Step ${step}"
}

load_state() {
    if [[ -f "${STATE_FILE}" ]]; then
        source "${STATE_FILE}"
        if [[ -n "${SELECTED_TYPES_STR}" ]]; then
            read -ra SELECTED_TYPES <<< "${SELECTED_TYPES_STR}"
        fi
        return 0
    fi
    return 1
}

clear_state() {
    if [[ -f "${STATE_FILE}" ]]; then
        rm -f "${STATE_FILE}"
    fi
}

is_step_done() {
    local target_step=$1
    local current_step=${STEP:-0}
    [[ ${current_step} -ge ${target_step} ]]
}

find_existing_work_dirs() {
    local pattern="AgentCanary_[0-9]*_[0-9]*"
    mkdir -p "${WORKSPACES_DIR}"
    ls -d "${WORKSPACES_DIR}"/${pattern} 2>/dev/null | sort -r
}

show_progress() {
    echo ""
    echo "=========================================="
    echo "  Build Progress"
    echo "=========================================="

    local step=${STEP:-0}
    local status_icon

    for i in 1 2; do
        if [[ ${step} -ge ${i} ]]; then
            status_icon="\033[32m✓\033[0m"
        else
            status_icon="\033[33m○\033[0m"
        fi
        case $i in
            1) printf "  ${status_icon} Step 1: Create workspace\n" ;;
            2) printf "  ${status_icon} Step 2: Build Docker images\n" ;;
        esac
    done
    echo "=========================================="
    echo ""
}

select_image_types() {
    echo ""
    echo "=========================================="
    echo "  Select Image Types to Build"
    echo "=========================================="
    echo ""
    echo "Available image types:"
    echo ""
    echo "  [1] official - Base image (OpenClaw + custom skills + mock-api server)"
    echo "  [2] offical_shield - official + openclaw-shield security plugin"
    echo "  [3] offical_secureclaw - official + SecureClaw security plugin"
    echo "  [4] offical_clawkeeper - official + ClawKeeper security plugin"
    echo ""
    echo "  [A] Build all (default)"
    echo "  [Q] Quit"
    echo ""
    read -p "Select image types (comma-separated, e.g. 1,2,3) [A]: " type_choice

    if [[ -z "${type_choice}" ]]; then
        type_choice="A"
    fi

    if [[ "${type_choice}" =~ ^[Qq]$ ]]; then
        log_info "Cancelled by user"
        exit 0
    fi

    SELECTED_TYPES=()
    if [[ "${type_choice}" =~ ^[Aa]$ ]]; then
        SELECTED_TYPES=("${IMAGE_TYPES[@]}")
    else
        IFS=',' read -ra choices <<< "${type_choice}"
        for choice in "${choices[@]}"; do
            choice=$(echo "${choice}" | tr -d ' ')
            case ${choice} in
                1) SELECTED_TYPES+=("official") ;;
                2) SELECTED_TYPES+=("offical_shield") ;;
                3) SELECTED_TYPES+=("offical_secureclaw") ;;
                4) SELECTED_TYPES+=("offical_clawkeeper") ;;
                *) log_warn "Skipping invalid choice: ${choice}" ;;
            esac
        done
    fi

    if [[ ${#SELECTED_TYPES[@]} -eq 0 ]]; then
        log_error "No image types selected"
        exit 1
    fi

    log_info "Will build: ${SELECTED_TYPES[*]}"
}

prepare_build_context() {
    local image_type=$1
    BUILD_DIR="${WORK_DIR}/build_${image_type}"
    local prepare_script="${IMAGES_DIR}/${image_type}/prepare.sh"

    mkdir -p "${BUILD_DIR}"

    if [[ -f "${prepare_script}" ]]; then
        log_info "Running ${image_type}/prepare.sh..."
        if bash "${prepare_script}" "${BUILD_DIR}" "" "${PROJECT_DIR}"; then
            log_success "Data preparation complete"
        else
            log_error "Data preparation failed"
            return 1
        fi
    else
        log_error "prepare.sh not found: ${prepare_script}"
        return 1
    fi
}

get_docker_proxy_args() {
    if [[ "${DOCKER_PROXY_ENABLED}" == "true" ]]; then
        echo "${DOCKER_EXTRA_BUILD_ARGS} --build-arg http_proxy=${DOCKER_PROXY_URL} --build-arg https_proxy=${DOCKER_PROXY_URL}"
    else
        echo ""
    fi
}

build_image() {
    local image_type=$1
    local lowercase_type=$(echo "${image_type}" | tr '[:upper:]' '[:lower:]')
    local image_tag="openclaw-${lowercase_type}-v${TIMESTAMP}"

    log_info "Preparing to build ${image_type} image..."

    if ! prepare_build_context "${image_type}"; then
        return 1
    fi

    log_info "Building image: ${image_tag}"
    log_info "Build directory: ${BUILD_DIR}"

    cd "${BUILD_DIR}"
    PROXY_ARGS=$(get_docker_proxy_args)
    if [[ -n "${PROXY_ARGS}" ]]; then
        log_info "Docker build args: ${PROXY_ARGS}"
    else
        log_info "Docker build args: no proxy"
    fi

    if docker build -f Dockerfile -t "${image_tag}" ${PROXY_ARGS} .; then
        log_success "Image built: ${image_tag}"
        return 0
    else
        log_error "Image build failed: ${image_tag}"
        return 1
    fi
}

# ============================================================================
# Main flow
# ============================================================================

log_info "=========================================="
log_info "AgentCanary Docker Image Builder"
log_info "=========================================="

if [[ "${DOCKER_PROXY_ENABLED}" == "true" ]]; then
    log_info "Proxy enabled: ${DOCKER_PROXY_URL}"
    if [[ -n "${DOCKER_EXTRA_BUILD_ARGS}" ]]; then
        log_info "Extra build args: ${DOCKER_EXTRA_BUILD_ARGS}"
    fi
else
    log_info "Proxy: disabled (use --proxy URL to enable)"
fi

# Check prerequisites
log_info "Checking dependencies..."
check_command docker

if [[ ! -d "${IMAGES_DIR}" ]]; then
    log_error "Image config directory not found: ${IMAGES_DIR}"
    exit 1
fi

# Check for existing workspaces
EXISTING_DIRS=$(find_existing_work_dirs)

if [[ -n "${EXISTING_DIRS}" ]]; then
    echo ""
    echo "=========================================="
    echo "  Existing Workspaces"
    echo "=========================================="
    echo ""

    WORK_DIR_ARRAY=()
    i=1
    while IFS= read -r dir; do
        dir_name=$(basename "${dir}")
        state_file="${dir}/.build_state"

        _st=0
        if [[ -f "${state_file}" ]]; then
            _st=$(grep "^STEP=" "${state_file}" | cut -d'=' -f2)
            if [[ -n "${_st}" ]]; then
                status="Step ${_st}/2"
            else
                status="has state file"
            fi
        else
            status="no state file"
        fi

        printf "  [%d] %-30s (%s)\n" "$i" "${dir_name}" "${status}"
        WORK_DIR_ARRAY+=("${dir}")
        ((i++))
    done <<< "${EXISTING_DIRS}"

    echo ""
    echo "  [N] Create new workspace (default)"
    echo "  [Q] Quit"
    echo ""
    read -p "Select workspace number or action [N]: " dir_choice

    if [[ -z "${dir_choice}" ]]; then
        dir_choice="N"
    fi

    if [[ "${dir_choice}" =~ ^[Qq]$ ]]; then
        log_info "Cancelled by user"
        exit 0
    elif [[ "${dir_choice}" =~ ^[Nn]$ ]]; then
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        WORK_DIR_NAME="AgentCanary_${TIMESTAMP}"
        WORK_DIR="${WORKSPACES_DIR}/${WORK_DIR_NAME}"
        STATE_FILE="${WORK_DIR}/.build_state"
        STEP=0
        mkdir -p "${WORK_DIR}"
        log_info "Created new workspace: ${WORK_DIR}"
    else
        dir_choice=${dir_choice:-1}
        if [[ ${dir_choice} -lt 1 || ${dir_choice} -gt ${#WORK_DIR_ARRAY[@]} ]]; then
            log_error "Invalid selection"
            exit 1
        fi

        SELECTED_DIR="${WORK_DIR_ARRAY[$((dir_choice-1))]}"
        STATE_FILE="${SELECTED_DIR}/.build_state"

        if [[ -f "${STATE_FILE}" ]]; then
            load_state
            WORK_DIR="${SELECTED_DIR}"
            show_progress

            echo "Choose action:"
            echo "  1) Resume - continue from last checkpoint"
            echo "  2) Restart - delete and start fresh"
            echo "  3) Quit"
            echo ""
            read -p "Enter choice [1/2/3]: " choice

            case ${choice} in
                1)
                    log_info "Resuming from Step ${STEP}..."
                    log_info "Proxy: ${DOCKER_PROXY_ENABLED} (${DOCKER_PROXY_URL})"
                    log_info "Selected types: ${SELECTED_TYPES[*]}"
                    ;;
                2)
                    log_warn "Will delete: ${SELECTED_DIR}"
                    read -p "Confirm? [y/N]: " confirm
                    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
                        rm -rf "${SELECTED_DIR}"
                        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
                        WORK_DIR_NAME="AgentCanary_${TIMESTAMP}"
                        WORK_DIR="${WORKSPACES_DIR}/${WORK_DIR_NAME}"
                        STATE_FILE="${WORK_DIR}/.build_state"
                        STEP=0
                        mkdir -p "${WORK_DIR}"
                        log_info "Deleted old workspace, created: ${WORK_DIR}"
                    else
                        log_info "Cancelled"
                        exit 0
                    fi
                    ;;
                3)
                    log_info "Cancelled by user"
                    exit 0
                    ;;
                *)
                    log_error "Invalid choice"
                    exit 1
                    ;;
            esac
        else
            log_warn "Workspace has no state file: ${SELECTED_DIR}"
            echo ""
            echo "Choose action:"
            echo "  1) Use this workspace"
            echo "  2) Restart - delete and start fresh"
            echo "  3) Quit"
            echo ""
            read -p "Enter choice [1/2/3]: " choice

            case ${choice} in
                1)
                    WORK_DIR="${SELECTED_DIR}"
                    STATE_FILE="${WORK_DIR}/.build_state"
                    dir_name=$(basename "${WORK_DIR}")
                    TIMESTAMP=$(echo "${dir_name}" | sed 's/AgentCanary_//')
                    STEP=0
                    log_info "Using workspace with timestamp: ${TIMESTAMP}"
                    ;;
                2)
                    log_warn "Will delete: ${SELECTED_DIR}"
                    read -p "Confirm? [y/N]: " confirm
                    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
                        rm -rf "${SELECTED_DIR}"
                        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
                        WORK_DIR_NAME="AgentCanary_${TIMESTAMP}"
                        WORK_DIR="${WORKSPACES_DIR}/${WORK_DIR_NAME}"
                        STATE_FILE="${WORK_DIR}/.build_state"
                        STEP=0
                        mkdir -p "${WORK_DIR}"
                        log_info "Deleted old workspace, created: ${WORK_DIR}"
                    else
                        log_info "Cancelled"
                        exit 0
                    fi
                    ;;
                3)
                    log_info "Cancelled by user"
                    exit 0
                    ;;
                *)
                    log_error "Invalid choice"
                    exit 1
                    ;;
            esac
        fi
    fi
else
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    WORK_DIR_NAME="AgentCanary_${TIMESTAMP}"
    WORK_DIR="${WORKSPACES_DIR}/${WORK_DIR_NAME}"
    STATE_FILE="${WORK_DIR}/.build_state"
    STEP=0
    mkdir -p "${WORK_DIR}"
    log_info "Created workspace: ${WORK_DIR}"
fi

log_info "Workspace: ${WORK_DIR}"

# ============================================================================
# Step 1: Create workspace
# ============================================================================
if ! is_step_done 1; then
    log_info "Step 1: Creating workspace..."
    save_state 1
fi
log_success "Step 1 complete"

# ============================================================================
# Select image types
# ============================================================================
if [[ ${#SELECTED_TYPES[@]} -eq 0 ]]; then
    select_image_types
fi

# ============================================================================
# Step 2: Build Docker images
# ============================================================================
if ! is_step_done 2; then
    log_info "Step 2: Building Docker images..."

    BUILD_SUCCESS=true
    for image_type in "${SELECTED_TYPES[@]}"; do
        if build_image "${image_type}"; then
            log_success "${image_type} image built successfully"
        else
            log_error "${image_type} image build failed"
            BUILD_SUCCESS=false
        fi
    done

    if [[ "${BUILD_SUCCESS}" == "true" ]]; then
        save_state 2
        log_success "Step 2 complete"
    else
        log_error "Some images failed to build. Check errors above."
        log_info "Re-run this script to resume."
        exit 1
    fi
else
    log_success "Step 2 already complete (resumed from checkpoint)"
fi

# ============================================================================
# Done
# ============================================================================
log_success "=========================================="
log_success "Build complete!"
log_success "=========================================="
echo ""
echo "Results:"
echo "  - Workspace: ${WORK_DIR}"
echo "  - Timestamp: ${TIMESTAMP}"
echo ""
echo "Image tags:"

VERIFIED_IMAGES=()
for image_type in "${SELECTED_TYPES[@]}"; do
    lowercase_type=$(echo "${image_type}" | tr '[:upper:]' '[:lower:]')
    image_tag="openclaw-${lowercase_type}-v${TIMESTAMP}"
    if docker image inspect "${image_tag}" &>/dev/null; then
        echo "  - ${image_type}: ${image_tag} ✓"
        VERIFIED_IMAGES+=("${image_type}")
    else
        echo "  - ${image_type}: ${image_tag} ✗ (image not found)"
    fi
done

if [[ ${#VERIFIED_IMAGES[@]} -eq 0 ]]; then
    log_error "No images were built successfully"
    exit 1
fi

echo ""
echo "Usage:"
for image_type in "${VERIFIED_IMAGES[@]}"; do
    lowercase_type=$(echo "${image_type}" | tr '[:upper:]' '[:lower:]')
    echo "  docker run --rm -it openclaw-${lowercase_type}-v${TIMESTAMP} bash"
done
echo ""
