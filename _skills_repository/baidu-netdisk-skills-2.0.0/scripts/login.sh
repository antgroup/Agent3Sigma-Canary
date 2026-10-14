#!/bin/bash
# bdpan OOB Login script
# For manual authorization login in non GUI GUI environments

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
            echo "  --yes, -y    Skip security confirmation (for automation)"
            echo "  --help       Show help information"
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

# Check bdpan Is it installed
if ! command -v bdpan &> /dev/null; then
    log_error "bdpan Not installed. Please run first: bash scripts/install.sh"
    exit 1
fi

# Check the current login status
log_info "Check login status..."

# Get bdpan version
BDPAN_VERSION=$(bdpan version 2>/dev/null | head -1 || echo "unknown")

if bdpan whoami 2>/dev/null | grep -q "Logged in"; then
    log_warn "Already logged in; no need to log in again"
    bdpan whoami
    exit 0
fi

log_info "Not logged in. Starting the OOB authorization flow..."

# Security Disclaimer
echo ""
echo -e "${RED}┌──────────────────────────────────────────────────────────────┐${NC}"
echo -e "${RED}│          ⚠️  baidu-netdisk-skills Public Beta Security Notice & Disclaimer (BETA)       │${NC}"
echo -e "${RED}├──────────────────────────────────────────────────────────────┤${NC}"
echo -e "${RED}│${NC} 1. [Testing Phase] This tool is in public beta and is intended for technical discussion only.               ${RED}│${NC}"
echo -e "${RED}│${NC}    Be sure to back up important data in your cloud drive.                               ${RED}│${NC}"
echo -e "${RED}│${NC} 2. [Responsible Use] AI Agent Behavior is unpredictable, so monitor it in real time             ${RED}│${NC}"
echo -e "${RED}│${NC}    [Manually review the command execution process and take responsibility for the consequences.                  ${RED}│${NC}"
echo -e "${RED}│${NC} 3. [Security Reminder] Never scan to authorize in someone else’s, public, or untrusted environment                ${RED}│${NC}"
echo -e "${RED}│${NC}    to avoid having your cloud drive data stolen!                              ${RED}│${NC}"
echo -e "${RED}│${NC}    After using it in a public environment, be sure to                             ${RED}│${NC}"
echo -e "${RED}│${NC}    [bdpan logout] revoke authorization completely.                             ${RED}│${NC}"
echo -e "${RED}│${NC} 4. [Do Not Disclose] Strictly protect the configuration files and Token,                     ${RED}│${NC}"
echo -e "${RED}│${NC}    Never expose them in public repositories or conversations!                                ${RED}│${NC}"
echo -e "${RED}├──────────────────────────────────────────────────────────────┤${NC}"
echo -e "${RED}│${NC} Using this tool means you have read and agree to the terms above. Data security is everyone’s responsibility.  ${RED}│${NC}"
echo -e "${RED}└──────────────────────────────────────────────────────────────┘${NC}"
echo ""

# user confirmation
if [ "$SKIP_CONFIRM" = "yes" ]; then
    log_info "Automatic mode: skipping security confirmation"
else
    echo -n -e "${YELLOW}I have read the security notice above and confirm that I want to continue logging in? [y/N] ${NC}"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Login canceled"
        exit 0
    fi
fi

# get authorization link
log_info "Getting the authorization link..."

# Check whether --get-auth-url Parameter
if bdpan login --help 2>/dev/null | grep -q "get-auth-url"; then
    # New version; supports --get-auth-url
    # Add --accept-disclaimer for first-time use (disclaimer already shown by this script)
    AUTH_URL=$(bdpan login --get-auth-url --accept-disclaimer 2>/dev/null || echo "")

    if [ -z "$AUTH_URL" ]; then
        log_error "Failed to get the authorization link"
        exit 1
    fi
else
    # Old version; trying to run login capture output
    log_warn "The current version may not support --get-auth-url, Try compatibility mode..."
    log_error "current bdpan version: ${BDPAN_VERSION}"
    log_error "Please upgrade to a version that supports --get-auth-url the bdpan version (>= 3.0.0)"
    log_error "Upgrade method: bash scripts/install.sh --force"
    exit 1
fi

# Display the authorization link (supports OSC 8 terminal hyperlinks that can be clicked to open in a browser)
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Open the following link in a browser to authorize:${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
# OSC 8 Hyperlink format:\e]8;;URL\e\\display text\e]8;;\e\\
# Supports iTerm2, VS Code Terminal, Wezterm, GNOME Terminal, Windows Terminal and others
# Unsupported terminals gracefully fall back to displaying text only
echo -e "\033]8;;${AUTH_URL}\033\\${YELLOW}${AUTH_URL}${NC}\033]8;;\033\\"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Tip:${NC}"
echo -e "${YELLOW}1. Click the link above to open it in a browser (if your terminal supports this)${NC}"
echo -e "${YELLOW}2. The link is valid for 10 minutes${NC}"
echo -e "${YELLOW}3. After authorization succeeds, the browser will display a 32 character authorization code${NC}"
echo -e "${YELLOW}4. Copy the authorization code and paste it below${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Prompt the user to enter the authorization code
echo -n "Enter the authorization code displayed in the browser (32 hexadecimal characters): "
read -r AUTH_CODE

if [ -z "$AUTH_CODE" ]; then
    log_error "The authorization code cannot be empty"
    exit 1
fi

# Validate the authorization code format:32 hexadecimal characters
if ! echo "$AUTH_CODE" | grep -qE '^[a-fA-F0-9]{32}$'; then
    log_error "Invalid authorization code format (must be 32 hexadecimal characters, such as: ca0ee3070f75d0246357e5c74d525bda)"
    log_error "Current input: ${AUTH_CODE}"
    log_error "Please make sure you copied the entire authorization code"
    exit 1
fi

# Log in using the authorization code
log_info "Logging in using the authorization code..."

# Use stdin Safely pass the authorization code to avoid exposing it in ps / /proc/PID/cmdline leaking
if bdpan login --help 2>/dev/null | grep -q "set-code-stdin"; then
    # Pass --accept-disclaimer since disclaimer was already shown by this script
    echo "$AUTH_CODE" | bdpan login --set-code-stdin --accept-disclaimer
else
    unset AUTH_CODE
    log_error "current bdpan version is not supported --set-code-stdin(secure authorization code passing)"
    log_error "current bdpan version: ${BDPAN_VERSION}"
    log_error "Please upgrade to >= 3.6.2: bash scripts/install.sh --force"
    exit 1
fi

# Clear the authorization code from memory immediately
unset AUTH_CODE

# Verify login
if bdpan whoami &> /dev/null; then
    log_info "✓ Login successful!"
    bdpan whoami
else
    log_error "Login failed. Please check that the authorization code is correct"
    exit 1
fi
