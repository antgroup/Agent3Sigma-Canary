#!/bin/bash
# bdpan CLI One-click installation script
# Automatically detect the platform architecture and download the corresponding installer

set -e

# bdpan CLI Installer version (kept in sync with CDN the release version)
VERSION="3.7.3"
CDN_BASE="https://issuecdn.baidupcs.com/issue/netdisk/ai-bdpan/installer/${VERSION}"

# Security: allowed CDN domains (only these hosts are trusted for downloads)
ALLOWED_CDN_HOSTS="issuecdn.baidupcs.com"

# Security: maximum installer file size (50 MB) to prevent abuse
MAX_INSTALLER_SIZE=$((50 * 1024 * 1024))

# Installer SHA256 checksum (update with each release)
# Use function instead of associative array for Bash 3.x compatibility (macOS default)
get_checksum() {
    case "$1" in
        "darwin-amd64") echo "f49b3577ecd8b596f21e30b1bb8458a31c7ec644c5c4b64da444cea6bbc089cf" ;;
        "darwin-arm64") echo "8c3a6d3d427e2661a08adfa1acfce4ce849164ba73b9b60662620f7140f86b40" ;;
        "linux-amd64")  echo "1678837c5ce6978f6491e76b10e344fba2beef6f81eb067c7ecc5668cf38fedb" ;;
        "linux-arm64")  echo "7692f828a1af10289274e6951225fcbe9ad3c0664ebee0b492c410855220c197" ;;
        *) echo "" ;;
    esac
}

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Security: validate URL against allowed CDN hosts
validate_download_url() {
    local url="$1"
    # Enforce HTTPS
    if [[ ! "$url" =~ ^https:// ]]; then
        log_error "Security: download URL must use HTTPS (got: $url)"
        exit 1
    fi
    # Extract hostname and validate against allowlist
    local host
    host=$(echo "$url" | sed -E 's|^https://([^/]+).*|\1|')
    local allowed=false
    for allowed_host in $ALLOWED_CDN_HOSTS; do
        if [ "$host" = "$allowed_host" ]; then
            allowed=true
            break
        fi
    done
    if [ "$allowed" != true ]; then
        log_error "Security: download host '$host' is not in the allowed list ($ALLOWED_CDN_HOSTS)"
        exit 1
    fi
}

# Security: validate downloaded file size
validate_file_size() {
    local file="$1"
    local max_size="$2"
    local file_size
    if [[ "$(uname -s)" == "Darwin" ]]; then
        file_size=$(stat -f%z "$file" 2>/dev/null || echo 0)
    else
        file_size=$(stat -c%s "$file" 2>/dev/null || echo 0)
    fi
    if [ "$file_size" -gt "$max_size" ]; then
        log_error "Security: downloaded file exceeds maximum allowed size (${file_size} > ${max_size} bytes)"
        rm -f "$file"
        exit 1
    fi
    if [ "$file_size" -eq 0 ]; then
        log_error "Security: downloaded file is empty"
        rm -f "$file"
        exit 1
    fi
}

# Detect the operating system
detect_os() {
    case "$(uname -s)" in
        Darwin)
            echo "darwin"
            ;;
        Linux)
            echo "linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            log_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
}

# Detect the architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "amd64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        *)
            log_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
}

# Main function
main() {
    local force="no"
    local skip_download="no"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --yes|-y|--force|-f)
                force="yes"
                shift
                ;;
            --skip-download)
                skip_download="yes"
                shift
                ;;
            --version|-v)
                echo "bdpan install script v${VERSION}"
                exit 0
                ;;
            --help|-h)
                echo "Usage: $0 [Options]"
                echo ""
                echo "Options:"
                echo "  --yes, -y           Non-interactive installation (skip confirmation)"
                echo "  --force, -f         Force reinstallation"
                echo "  --skip-download     Skip the download and use the local copy directly bdpan tool"
                echo "                      (Must set BDPAN_BIN environment variable)"
                echo "  --version           Display version information"
                echo "  --help              Show help information"
                echo ""
                echo "Environment variables:"
                echo "  BDPAN_BIN           Specify the local bdpan tool path"
                echo ""
                echo "Example:"
                echo "  $0                          # Interactive installation"
                echo "  $0 --yes                    # Non-interactive installation"
                echo "  BDPAN_BIN=/path/to/bdpan $0 --skip-download"
                echo "                              # Use the local tool"
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                echo "Use --help View help information"
                exit 1
                ;;
        esac
    done

    # Check whether local mode is enabled bdpan tool
    if [ "$skip_download" = "yes" ]; then
        if [ -z "$BDPAN_BIN" ]; then
            log_error "--skip-download requires BDPAN_BIN environment variable to specify the local tool path"
            echo "Example: BDPAN_BIN=/path/to/bdpan $0 --skip-download"
            exit 1
        fi
        if [ ! -x "$BDPAN_BIN" ]; then
            log_error "Specified bdpan tool does not exist or is not executable: $BDPAN_BIN"
            exit 1
        fi

        log_info "Using local bdpan tool: $BDPAN_BIN"
        local current_version=$("$BDPAN_BIN" version 2>/dev/null | head -1 || echo "unknown")
        log_info "bdpan CLI version: ${current_version}"
        log_info "✓ Configuration complete!"
        echo ""
        echo "Usage:"
        echo "  export BDPAN_BIN=\"$BDPAN_BIN\""
        echo "  bash scripts/login.sh"
        echo ""
        exit 0
    fi

    # Detect platform
    local os=$(detect_os)
    local arch=$(detect_arch)

    log_info "Platform detected: ${os}/${arch}"

    # Check whether already installed
    if command -v bdpan &> /dev/null; then
        local current_version=$(bdpan version 2>/dev/null | head -1 || echo "unknown")
        log_warn "bdpan CLI Already installed (version: ${current_version})"
        if [ "$force" = "yes" ]; then
            log_info "Force reinstallation..."
        else
            read -p "Reinstall?? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Installation canceled"
                exit 0
            fi
        fi
    fi

    # Build installer filename and URL
    local installer_name="bdpan-installer-${os}-${arch}"
    local installer_url="${CDN_BASE}/${installer_name}"

    # Windows Special handling
    if [ "$os" = "windows" ]; then
        installer_name="${installer_name}.exe"
        installer_url="${CDN_BASE}/${installer_name}"
    fi

    # Security: validate download URL before fetching
    validate_download_url "${installer_url}"

    log_info "Downloading bdpan CLI Installer (v${VERSION})..."
    log_info "Download URL: ${installer_url}"

    # Determine installation directory
    local install_dir="${BDPAN_INSTALL_DIR:-$HOME/.local/bin}"

    # Security: use isolated temp directory for download, not the install dir
    local tmp_dir
    tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/bdpan-install-XXXXXX")
    # Ensure temp dir is cleaned up on exit
    trap 'rm -rf "${tmp_dir}"' EXIT
    local installer_path="${tmp_dir}/${installer_name}"

    # Ensure the installation directory exists
    mkdir -p "${install_dir}"

    # Download the installer to the installation directory
    log_info "Downloading the installer to: ${installer_path}"
    if command -v curl &> /dev/null; then
        curl -fsSL -o "${installer_path}" "${installer_url}"
    elif command -v wget &> /dev/null; then
        wget -q -O "${installer_path}" "${installer_url}"
    else
        log_error "Could not find curl or wget, Please download the installer manually"
        log_error "Download URL: ${installer_url}"
        exit 1
    fi

    # Security: validate file size before checksum
    validate_file_size "${installer_path}" "${MAX_INSTALLER_SIZE}"

    log_info "Installer downloaded. Verifying integrity..."

    # SHA256 Integrity verification (required)
    local platform_key="${os}-${arch}"
    local expected_checksum="$(get_checksum "$platform_key")"
    if [ -n "$expected_checksum" ]; then
        local actual_checksum=""
        if command -v sha256sum &> /dev/null; then
            actual_checksum=$(sha256sum "${installer_path}" | awk '{print $1}')
        elif command -v shasum &> /dev/null; then
            actual_checksum=$(shasum -a 256 "${installer_path}" | awk '{print $1}')
        else
            log_error "Could not find sha256sum/shasum tool; unable to verify installer integrity"
            rm -f "${installer_path}"
            exit 1
        fi

        if [ "$actual_checksum" != "$expected_checksum" ]; then
            log_error "SHA256 Verification failed! The file may have been tampered with"
            log_error "  Expected: ${expected_checksum}"
            log_error "  Actual: ${actual_checksum}"
            rm -f "${installer_path}"
            exit 1
        fi
        log_info "SHA256 Verification passed"
    else
        log_warn "Current platform ${platform_key} no preconfigured checksum; skipping integrity verification"
    fi

    # Add execute permission (non- Windows)
    if [ "$os" != "windows" ]; then
        chmod +x "${installer_path}"
    fi

    # Run the installer after user confirmation
    if [ "$force" != "yes" ]; then
        echo ""
        log_info "Installer downloaded and passed integrity verification"
        log_info "Installer path: ${installer_path}"
        echo ""
        echo -e "${YELLOW}About to run the installer and install bdpan CLI locally.${NC}"
        echo -e "${YELLOW}To review the installer first, press N Cancel, then inspect the file contents manually.${NC}"
        echo ""
        read -p "Run the installation now?? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Execution canceled. The installer has been saved to: ${installer_path}"
            log_info "You can review it manually and then run: ${installer_path} --yes"
            exit 0
        fi
    fi

    # Security: ensure installer is not a script/text file masquerading as binary
    local file_type
    file_type=$(file -b "${installer_path}" 2>/dev/null || echo "unknown")
    if echo "$file_type" | grep -qiE 'text|script|ascii|html'; then
        log_error "Security: installer appears to be a text/script file, not a binary executable"
        log_error "File type: ${file_type}"
        rm -f "${installer_path}"
        exit 1
    fi

    # Run the installer
    "${installer_path}" --yes

    # Clean up the installer (also handled by trap)
    rm -f "${installer_path}"

    # Verify installation
    log_info "Verify installation..."
    if command -v bdpan &> /dev/null; then
        local installed_version=$(bdpan version 2>/dev/null | head -1 || echo "unknown")
        log_info "✓ bdpan CLI Installation successful!(version: ${installed_version})"

        # Register with the version management system so that bdpan update working properly
        log_info "Register with the version management system..."
        bdpan install --force 2>/dev/null || log_warn "Version registration skipped (does not affect usage)"

        echo ""

        # Security Disclaimer
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

        echo "Quick Start:"
        echo "  1. Log in: bash scripts/login.sh"
        echo "  2. View help: bdpan --help"
        echo ""
    else
        log_error "Installation failed. Check PATH whether it includes ~/.local/bin"
        echo "You can add it manually: export PATH=\"\$HOME/.local/bin:\$PATH\""
        exit 1
    fi
}

# Run the main function
main "$@"
