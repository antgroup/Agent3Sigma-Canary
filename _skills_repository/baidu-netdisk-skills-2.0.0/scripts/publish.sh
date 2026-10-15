#!/bin/bash
# ClawHub publish script for baidu-netdisk-skills skill
# Usage: bash scripts/publish.sh [--version <semver>] [--name <name>] [--changelog <text>] [--yes]

set -e

# Defaults
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_NAME="Baidu Netdisk"
VERSION=""
NAME=""
CHANGELOG=""
AUTO_YES=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "${CYAN}[STEP]${NC} $1"; }

usage() {
    cat <<EOF
Usage: bash scripts/publish.sh [options]

Options:
  --version <semver>    Version to publish (required, e.g. 1.5.2)
  --name <name>         Display name (default: "${DEFAULT_NAME}")
  --changelog <text>    Changelog text
  --yes                 Skip confirmation prompt
  -h, --help            Show this help message

Examples:
  bash scripts/publish.sh --version 1.5.3
  bash scripts/publish.sh --version 1.6.0 --name "Baidu Netdisk" --changelog "Added new features"
  bash scripts/publish.sh --version 1.5.4 --yes
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --name)
            NAME="$2"
            shift 2
            ;;
        --changelog)
            CHANGELOG="$2"
            shift 2
            ;;
        --yes)
            AUTO_YES=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Use default name if not specified
if [[ -z "$NAME" ]]; then
    NAME="$DEFAULT_NAME"
fi

# --- Pre-publish checks ---

log_step "Running pre-publish checks..."

# 1. Check clawhub CLI
if ! command -v clawhub &>/dev/null; then
    log_error "clawhub CLI not found. Please install it first."
    exit 1
fi
log_info "clawhub CLI found: $(command -v clawhub)"

# 2. Check clawhub login
if ! clawhub whoami &>/dev/null; then
    log_error "Not logged in to ClawHub. Please run: clawhub login"
    exit 1
fi
WHOAMI=$(clawhub whoami 2>&1 || true)
log_info "Logged in as: ${WHOAMI}"

# 3. Check version is provided
if [[ -z "$VERSION" ]]; then
    log_error "Version is required. Use --version <semver>"
    echo ""
    usage
fi

# 4. Validate semver format
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
    log_error "Invalid version format: $VERSION (expected semver, e.g. 1.5.2)"
    exit 1
fi

# 5. Check SKILL.md exists
if [[ ! -f "$SKILL_DIR/SKILL.md" ]]; then
    log_error "SKILL.md not found in $SKILL_DIR"
    exit 1
fi
log_info "SKILL.md found"

# 6. Check git status (warn if dirty)
if command -v git &>/dev/null && [[ -d "$SKILL_DIR/.git" ]]; then
    if [[ -n "$(git -C "$SKILL_DIR" status --porcelain 2>/dev/null)" ]]; then
        log_warn "Git working directory has uncommitted changes"
    else
        log_info "Git working directory is clean"
    fi
fi

# --- Confirmation ---

echo ""
echo "========================================="
echo "  ClawHub Publish Summary"
echo "========================================="
echo "  Skill directory : $SKILL_DIR"
echo "  Display name    : $NAME"
echo "  Version         : $VERSION"
if [[ -n "$CHANGELOG" ]]; then
echo "  Changelog       : $CHANGELOG"
fi
echo "========================================="
echo ""

if [[ "$AUTO_YES" != true ]]; then
    read -rp "Proceed with publish? [y/N] " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Publish cancelled."
        exit 0
    fi
fi

# --- Publish ---

log_step "Publishing to ClawHub..."

CMD=(clawhub publish "$SKILL_DIR" --version "$VERSION" --name "$NAME")

if [[ -n "$CHANGELOG" ]]; then
    CMD+=(--changelog "$CHANGELOG")
fi

echo "  Running: ${CMD[*]}"
echo ""

if "${CMD[@]}" 2>&1; then
    echo ""
    log_info "Successfully published ${NAME} v${VERSION} to ClawHub! 🎉"
else
    EXIT_CODE=$?
    echo ""
    log_error "Publish failed (exit code: $EXIT_CODE)."
    log_warn "If version already exists, try a higher version number."
    exit $EXIT_CODE
fi
