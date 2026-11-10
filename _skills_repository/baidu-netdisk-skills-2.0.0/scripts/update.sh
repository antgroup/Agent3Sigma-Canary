#!/bin/bash
# baidu-netdisk-skills Skill Auto-update script
# Check for and install updates through Baidu’s configuration API Skill file
# CLI Updates are managed by bdpan Managed independently; this script is not responsible for it

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_API="https://pan.baidu.com/act/v2/api/conf?conf_key=bd_skills"

# Security: allowed domains for config API and download URLs
# NOTE: must stay in sync with the "Download safety" clause in SKILL.md.
# Only the official Baidu CDN for skill update packages is trusted.
ALLOWED_CONFIG_HOSTS="pan.baidu.com"
ALLOWED_DOWNLOAD_HOSTS="issuecdn.baidupcs.com"

# Security: maximum update package size (100 MB) to prevent zip bombs
MAX_UPDATE_SIZE=$((100 * 1024 * 1024))

# Security: maximum number of files allowed in update zip
MAX_ZIP_FILES=500

# Directory containing the script (used to locate Skill files)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="${SKILL_DIR}/VERSION"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Security: validate URL against allowed host list
validate_url() {
    local url="$1"
    local allowed_hosts="$2"
    local context="$3"
    # Enforce HTTPS
    if [[ ! "$url" =~ ^https:// ]]; then
        log_error "Security: ${context} URL must use HTTPS (got: $url)"
        return 1
    fi
    # Extract hostname and validate against allowlist
    local host
    host=$(echo "$url" | sed -E 's|^https://([^/:]+).*|\1|')
    local allowed=false
    for allowed_host in $allowed_hosts; do
        if [ "$host" = "$allowed_host" ]; then
            allowed=true
            break
        fi
    done
    if [ "$allowed" != true ]; then
        log_error "Security: ${context} host '$host' is not in the allowed list ($allowed_hosts)"
        return 1
    fi
}

# Security: validate file size
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
        log_error "Security: file exceeds maximum allowed size (${file_size} > ${max_size} bytes)"
        return 1
    fi
    if [ "$file_size" -eq 0 ]; then
        log_error "Security: downloaded file is empty"
        return 1
    fi
}

# Security: validate zip contents for path traversal and file count
validate_zip_contents() {
    local zip_path="$1"
    # Check for path traversal in zip entries
    if unzip -l "$zip_path" 2>/dev/null | grep -qE '\.\./' ; then
        log_error "Security: zip contains path traversal entries (../) - rejecting"
        return 1
    fi
    # Check for absolute paths in zip entries
    if unzip -l "$zip_path" 2>/dev/null | awk 'NR>3{print $4}' | grep -qE '^/' ; then
        log_error "Security: zip contains absolute path entries - rejecting"
        return 1
    fi
    # Check file count to prevent zip bombs
    local file_count
    file_count=$(unzip -l "$zip_path" 2>/dev/null | tail -1 | awk '{print $2}')
    if [ "${file_count:-0}" -gt "$MAX_ZIP_FILES" ]; then
        log_error "Security: zip contains too many files (${file_count} > ${MAX_ZIP_FILES}) - possible zip bomb"
        return 1
    fi
}

# Version comparison: returns 0 means $1 > $2, 1 means $1 = $2, 2 means $1 < $2
version_compare() {
    if [ "$1" = "$2" ]; then
        return 1
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [ -z "${ver2[i]}" ]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 1
}

# Remove the v prefix from the version number (e.g. v1.2.0 → 1.2.0)
strip_v_prefix() {
    echo "$1" | sed 's/^v//'
}

# Get the local Skill version
get_local_version() {
    if [ -f "$VERSION_FILE" ]; then
        local raw=$(cat "$VERSION_FILE" | tr -d '[:space:]')
        strip_v_prefix "$raw"
    else
        echo "unknown"
    fi
}

# From query string Extract the specified key value from
# Usage: query_get "version=1.1.2&url=https://..." "version"
query_get() {
    local qs="$1"
    local key="$2"
    echo "$qs" | tr '&' '\n' | while IFS='=' read -r k v; do
        if [ "$k" = "$key" ]; then
            echo "$v"
            return 0
        fi
    done
}

# Request the configuration API and return skills_info query string
fetch_skills_info() {
    # Security: validate config API URL
    validate_url "$CONFIG_API" "$ALLOWED_CONFIG_HOSTS" "config API" || return 1

    local response=""

    if command -v curl &> /dev/null; then
        response=$(curl -fsSL --connect-timeout 10 --max-time 30 "$CONFIG_API" 2>/dev/null) || {
            log_error "Cannot connect to the configuration server. Check your network connection."
            return 1
        }
    elif command -v wget &> /dev/null; then
        response=$(wget -qO- --timeout=30 "$CONFIG_API" 2>/dev/null) || {
            log_error "Cannot connect to the configuration server. Check your network connection."
            return 1
        }
    else
        log_error "Could not find curl or wget"
        return 1
    fi

    # Check errno:From JSON extract from "errno": 0
    local errno=$(echo "$response" | grep -o '"errno"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*$')
    if [ "$errno" != "0" ]; then
        log_error "Configuration API returned an error (errno: ${errno:-unknown})"
        return 1
    fi

    # From response extract from skills_info value from
    # API In the response & may be encoded as \u0026, needs to be decoded
    local skills_info=$(echo "$response" | sed 's/\\u0026/\&/g' | grep -o 'version=[^"]*' | head -1 | sed 's/\\//g')

    if [ -z "$skills_info" ]; then
        log_error "Could not retrieve version configuration"
        return 1
    fi

    echo "$skills_info"
}

# Download and verify the update package
download_and_verify() {
    local remote_url="$1"
    local remote_version="$2"
    local zip_path="$3"

    if [ -z "$remote_url" ]; then
        log_error "Could not find Skill Download URL"
        return 1
    fi

    # Security: validate download URL
    validate_url "$remote_url" "$ALLOWED_DOWNLOAD_HOSTS" "download" || return 1

    log_info "Downloading Skill update package (v${remote_version})..."
    log_info "Download URL: ${remote_url}"

    # download zip
    if command -v curl &> /dev/null; then
        curl -fsSL -o "$zip_path" "$remote_url" || {
            log_error "download Skill Update package failed"
            return 1
        }
    elif command -v wget &> /dev/null; then
        wget -q -O "$zip_path" "$remote_url" || {
            log_error "download Skill Update package failed"
            return 1
        }
    fi

    # SHA256 Integrity verification (required)
    local checksum=$(query_get "$SKILLS_INFO" "checksum")
    if [ -z "$checksum" ]; then
        log_error "Configuration endpoint not provided checksum, Unable to verify update package integrity; update aborted"
        return 1
    fi

    local actual=""
    if command -v sha256sum &> /dev/null; then
        actual=$(sha256sum "$zip_path" | awk '{print $1}')
    elif command -v shasum &> /dev/null; then
        actual=$(shasum -a 256 "$zip_path" | awk '{print $1}')
    else
        log_error "Could not find sha256sum/shasum Tool: unable to verify update package integrity"
        return 1
    fi

    if [ "$actual" != "$checksum" ]; then
        log_error "SHA256 Verification failed! The file may have been tampered with"
        log_error "  Expected: ${checksum}"
        log_error "  Actual: ${actual}"
        rm -f "$zip_path"
        return 1
    fi
    log_info "SHA256 Verification passed"

    # Security: validate file size
    validate_file_size "$zip_path" "$MAX_UPDATE_SIZE" || {
        rm -f "$zip_path"
        return 1
    }

    # Security: validate zip contents for path traversal and zip bombs
    validate_zip_contents "$zip_path" || {
        rm -f "$zip_path"
        return 1
    }
}

# Apply update (extract and overwrite)
apply_update() {
    local zip_path="$1"
    local remote_version="$2"

    log_info "Extracting update..."

    # Security: use temp directory for extraction, then copy to skill dir
    local tmp_extract_dir
    tmp_extract_dir=$(mktemp -d "${TMPDIR:-/tmp}/bdpan-update-XXXXXX")
    trap 'rm -rf "${tmp_extract_dir}"' EXIT

    if command -v unzip &> /dev/null; then
        unzip -qo "$zip_path" -d "$tmp_extract_dir" || {
            log_error "Extraction failed"
            return 1
        }
    else
        log_error "Could not find unzip tool"
        return 1
    fi

    # Security: verify extracted contents don't contain suspicious files
    if find "$tmp_extract_dir" -name '*.sh' -o -name '*.bash' | head -1 | grep -q .; then
        log_warn "Update package contains shell scripts - please review before proceeding"
    fi

    # Copy verified files to skill directory
    cp -R "$tmp_extract_dir"/* "$SKILL_DIR/" || {
        log_error "Failed to copy update files"
        return 1
    }

    # Update VERSION file
    echo "$remote_version" > "$VERSION_FILE"

    # Clean up downloaded files
    rm -f "$zip_path"

    log_info "Skill Updated to v${remote_version}"
}

# Global variables
SKILLS_INFO=""

# Main function
main() {
    local check_only="no"
    local auto_yes="no"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check|-c)
                check_only="yes"
                shift
                ;;
            --yes|-y)
                auto_yes="yes"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [Options]"
                echo ""
                echo "Options:"
                echo "  --check, -c   Check for updates only; do not install"
                echo "  --yes, -y     Skip confirmation and update automatically"
                echo "  --help        Show help information"
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                echo "Use --help View help information"
                exit 1
                ;;
        esac
    done

    # Get local version
    local local_version=$(get_local_version)

    # Security: block Agent auto-updates outright.
    # This update path can replace any file in the skill directory, so we
    # require a human-initiated terminal invocation. Agents (Claude Code,
    # MCP servers, etc.) must not drive this script, even in --check mode.
    if [ -n "$CLAUDE_CODE" ] || [ -n "$ANTHROPIC_API_KEY" ] || [ -n "$MCP_SERVER" ]; then
        log_error "Agent The environment prohibits running the self-update script. Please run it manually in a local terminal:"
        log_error "  bash scripts/update.sh"
        exit 1
    fi

    # Show an up-front banner before any network call so the user sees
    # exactly what this script can do.
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  ⚠️  Skill Self-update script (please review manually)${NC}"
    echo -e "${YELLOW}----------------------------------------${NC}"
    echo -e "${YELLOW}  · Download only from issuecdn.baidupcs.com download${NC}"
    echo -e "${YELLOW}  · Will verify SHA256 and ZIP security${NC}"
    echo -e "${YELLOW}  · Will overwrite the files in this directory Skill file${NC}"
    echo -e "${YELLOW}  · If you did not initiate this, cancel immediately${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""

    # Request remote configuration
    log_info "Checking for updates..."
    SKILLS_INFO=$(fetch_skills_info) || {
        log_warn "Unable to retrieve update information. Please try again later"
        exit 1
    }

    # Parse the remote version and download URL (strip v prefix used for comparison)
    local remote_version=$(query_get "$SKILLS_INFO" "version")
    local remote_version_clean=$(strip_v_prefix "$remote_version")
    local remote_url=$(query_get "$SKILLS_INFO" "url")

    if [ -z "$remote_version" ]; then
        log_error "Configuration does not include version information"
        exit 1
    fi

    # Display status
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  baidu-netdisk-skills Skill Update check${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "  Local version: ${local_version}"
    echo -e "  Latest version: ${remote_version}"

    # Version comparison
    local needs_update="no"
    if [ "$local_version" = "unknown" ]; then
        echo -e "  Status:     ${YELLOW}Version unknown; update recommended${NC}"
        needs_update="yes"
    else
        set +e
        version_compare "$remote_version_clean" "$local_version"
        local cmp_result=$?
        set -e

        if [ $cmp_result -eq 0 ]; then
            echo -e "  Status:     ${YELLOW}A new version is available${NC}"
            needs_update="yes"
        else
            echo -e "  Status:     ${GREEN}Already up to date${NC}"
        fi
    fi

    echo ""

    # No update
    if [ "$needs_update" = "no" ]; then
        log_info "Skill Already up to date"
        exit 0
    fi

    # Check-only mode
    if [ "$check_only" = "yes" ]; then
        exit 0
    fi

    # Security restriction:Agent Prohibited in the environment --yes Skip confirmation
    if [ "$auto_yes" = "yes" ]; then
        if [ -n "$CLAUDE_CODE" ] || [ -n "$ANTHROPIC_API_KEY" ] || [ -n "$MCP_SERVER" ]; then
            log_warn "Detected Agent environment; ignoring --yes parameter and retaining user confirmation"
            auto_yes="no"
        fi
    fi

    # Step 1: Confirm whether to download the update package
    if [ "$auto_yes" != "yes" ]; then
        echo -n -e "${YELLOW}Download Skill v${remote_version} update package? [y/N] ${NC}"
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Update canceled"
            exit 0
        fi
    fi

    echo ""

    # Step 2: Download and verify the update package
    local zip_path="${SKILL_DIR}/baidu-netdisk-skills-v${remote_version}.zip"
    download_and_verify "$remote_url" "$remote_version" "$zip_path" || {
        log_error "Skill Update package download or verification failed"
        exit 1
    }

    # Step 3: Confirm whether to apply the update (confirm only after verification succeeds)
    if [ "$auto_yes" != "yes" ]; then
        echo ""
        log_info "The update package has been downloaded and passed the integrity check"
        log_info "Update package path: ${zip_path}"
        echo ""
        echo -e "${YELLOW}The update package is about to be extracted and overwrite the current Skill files.${NC}"
        echo -e "${YELLOW}To review the update package contents first, press N Cancel, then inspect it manually.${NC}"
        echo ""
        echo -n -e "${YELLOW}Apply the update now?? [y/N] ${NC}"
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Application canceled. The update package has been saved to: ${zip_path}"
            log_info "You can review it manually and then run: unzip -qo \"${zip_path}\" -d \"${SKILL_DIR}\""
            exit 0
        fi
    fi

    echo ""

    # Step 4: Apply the update
    apply_update "$zip_path" "$remote_version" || {
        log_error "Skill Update failed"
        exit 1
    }

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  ✓ Update complete${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Run the main function
main "$@"
