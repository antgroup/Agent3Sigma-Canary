#!/bin/bash
# bdpan CLI Uninstall script
# Remove bdpan binaries, configuration files, and authorization information

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default paths
DEFAULT_INSTALL_DIR="$HOME/.local/bin"
DEFAULT_CONFIG_DIR="$HOME/.config/bdpan"

# Parse arguments
SKIP_CONFIRM="no"
while [[ $# -gt 0 ]]; do
    case $1 in
        --yes|-y)
            SKIP_CONFIRM="yes"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [Options]"
            echo ""
            echo "Options:"
            echo "  --yes, -y    Skip confirmation prompts (for automation)"
            echo "  --help       Show help information"
            echo ""
            echo "Environment variables:"
            echo "  BDPAN_INSTALL_DIR  Binary installation directory (default: ~/.local/bin)"
            echo "  BDPAN_CONFIG_DIR   Configuration directory (default: ~/.config/bdpan)"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Determine the actual paths
INSTALL_DIR="${BDPAN_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
CONFIG_DIR="${BDPAN_CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"
BINARY_PATH="${INSTALL_DIR}/bdpan"

# Check what needs to be cleaned up
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  bdpan CLI Uninstall${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

found_items=0

# Check for the binary
if [ -f "$BINARY_PATH" ]; then
    binary_version=$("$BINARY_PATH" version 2>/dev/null | head -1 || echo "unknown")
    echo -e "  Binary: ${GREEN}${BINARY_PATH}${NC} (${binary_version})"
    found_items=$((found_items + 1))
else
    # Try which Find
    actual_path=$(command -v bdpan 2>/dev/null || echo "")
    if [ -n "$actual_path" ]; then
        BINARY_PATH="$actual_path"
        binary_version=$("$BINARY_PATH" version 2>/dev/null | head -1 || echo "unknown")
        echo -e "  Binary: ${GREEN}${BINARY_PATH}${NC} (${binary_version})"
        found_items=$((found_items + 1))
    else
        echo -e "  Binary: ${YELLOW}Could not find${NC}"
    fi
fi

# Check the configuration directory
if [ -d "$CONFIG_DIR" ]; then
    config_files=$(find "$CONFIG_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  Configuration directory:   ${GREEN}${CONFIG_DIR}/${NC} (${config_files} files)"
    found_items=$((found_items + 1))

    # Check for an active login session
    if [ -f "${CONFIG_DIR}/config.json" ]; then
        if command -v bdpan &> /dev/null && bdpan whoami 2>/dev/null | grep -q "Logged in"; then
            echo -e "  Login status:   ${RED}Logged in (authorization information will be cleared)${NC}"
        fi
    fi
else
    echo -e "  Configuration directory:   ${YELLOW}Could not find${NC}"
fi

echo ""

# Nothing to clean up
if [ "$found_items" -eq 0 ]; then
    log_info "No bdpan installation detected; nothing to uninstall"
    exit 0
fi

# user confirmation
if [ "$SKIP_CONFIRM" != "yes" ]; then
    echo -e "${RED}The items above will be permanently deleted. This action cannot be undone!${NC}"
    echo ""
    echo -n -e "${YELLOW}Confirm uninstall bdpan CLI? [y/N] ${NC}"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstall canceled"
        exit 0
    fi
fi

echo ""

# 1. Log out (clear the server-side session, if any)
if command -v bdpan &> /dev/null && bdpan whoami 2>/dev/null | grep -q "Logged in"; then
    log_info "Logging out..."
    bdpan logout 2>/dev/null || true
    log_info "✓ Logged out"
fi

# 2. Delete the configuration directory (including token, config.json and others)
if [ -d "$CONFIG_DIR" ]; then
    log_info "Deleting the configuration directory: ${CONFIG_DIR}/"
    rm -rf "$CONFIG_DIR"
    log_info "✓ Configuration directory deleted"
fi

# 3. Delete the binary
if [ -f "$BINARY_PATH" ]; then
    log_info "Deleting the binary: ${BINARY_PATH}"
    rm -f "$BINARY_PATH"
    log_info "✓ Binary deleted"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ bdpan CLI Completely uninstalled${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Cleaned up:"
echo "  - Binary (bdpan)"
echo "  - configuration files and authorization information (~/.config/bdpan/)"
echo ""
