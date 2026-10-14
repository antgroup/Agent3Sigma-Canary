#!/usr/bin/env bash
###############################################################################
# Helm Chart Helper
# A comprehensive Helm chart management tool for Kubernetes deployments.
#
# Powered by BytesAgain | bytesagain.com | hello@bytesagain.com
#
# Requirements: helm (v3+)
#
# Usage: script.sh <command> [arguments...]
#
# Commands:
#   create <chart>             Create a new Helm chart scaffold
#   lint <chart>               Lint a chart for issues
#   template <chart> [args]    Render chart templates locally
#   list [namespace]           List installed releases
#   status <release>           Show release status
#   values <chart>             Show chart default values
#   repo-add <name> <url>      Add a Helm repository
#   repo-list                  List configured repositories
#   repo-update                Update all repositories
#   search <keyword>           Search for charts
#   package <chart>            Package a chart for distribution
#   history <release>          Show release history
#   rollback <release> [rev]   Rollback a release
#   diff <chart> <release>     Show diff between chart and deployed release
#   help                       Show this help message
###############################################################################
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DATA_DIR="${HOME}/.local/share/helm-helper"
CHARTS_DIR="${DATA_DIR}/charts"
PACKAGES_DIR="${DATA_DIR}/packages"
LOG_FILE="${DATA_DIR}/helm-helper.log"

# Helm defaults
HELM_NAMESPACE="${HELM_NAMESPACE:-default}"
HELM_KUBECONFIG="${KUBECONFIG:-}"

BRAND="Powered by BytesAgain | bytesagain.com | hello@bytesagain.com"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

###############################################################################
# Utility functions
###############################################################################

_init() {
    mkdir -p "$DATA_DIR" "$CHARTS_DIR" "$PACKAGES_DIR"
    touch "$LOG_FILE"
}

_log() {
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$ts] $*" >> "$LOG_FILE"
}

_info()  { echo -e "${GREEN}[✓]${NC} $*"; }
_warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
_error() { echo -e "${RED}[✗]${NC} $*" >&2; }
_header(){ echo -e "${BOLD}${CYAN}═══ $* ═══${NC}"; }

_check_helm() {
    if ! command -v helm &>/dev/null; then
        _error "helm is not installed or not in PATH."
        echo ""
        echo "Install Helm v3:"
        echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
        echo ""
        echo "  Or via package manager:"
        echo "    macOS:         brew install helm"
        echo "    Snap:          sudo snap install helm --classic"
        echo "    Chocolatey:    choco install kubernetes-helm"
        echo "    apt (Debian):  sudo apt-get install helm"
        echo ""
        echo "  More: https://helm.sh/docs/intro/install/"
        exit 1
    fi

    # Verify version is v3+
    local version
    version="$(helm version --short 2>/dev/null | head -1)"
    if [[ "$version" == v2* ]]; then
        _error "Helm v2 detected ($version). This tool requires Helm v3+."
        exit 1
    fi
}

_helm() {
    local args=()
    if [[ -n "$HELM_NAMESPACE" ]]; then
        args+=(--namespace "$HELM_NAMESPACE")
    fi
    if [[ -n "$HELM_KUBECONFIG" ]]; then
        args+=(--kubeconfig "$HELM_KUBECONFIG")
    fi
    helm "${args[@]}" "$@"
}

_helm_global() {
    local args=()
    if [[ -n "$HELM_KUBECONFIG" ]]; then
        args+=(--kubeconfig "$HELM_KUBECONFIG")
    fi
    helm "${args[@]}" "$@"
}

_resolve_chart_path() {
    local chart="$1"
    # If it's a path that exists, use it directly
    if [[ -d "$chart" ]]; then
        echo "$chart"
        return 0
    fi
    # Check in charts dir
    if [[ -d "${CHARTS_DIR}/${chart}" ]]; then
        echo "${CHARTS_DIR}/${chart}"
        return 0
    fi
    # Check current directory
    if [[ -d "./${chart}" ]]; then
        echo "./${chart}"
        return 0
    fi
    # Return as-is (might be a repo reference like stable/nginx)
    echo "$chart"
}

###############################################################################
# Command implementations
###############################################################################

cmd_create() {
    local chart="${1:?Usage: $SCRIPT_NAME create <chart-name>}"

    _header "Create Helm Chart"

    local chart_path="${CHARTS_DIR}/${chart}"
    if [[ -d "$chart_path" ]]; then
        _warn "Chart directory already exists: $chart_path"
        read -rp "Overwrite? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            _warn "Aborted."
            return 0
        fi
        rm -rf "$chart_path"
    fi

    helm create "$chart_path" 2>&1 || {
        _error "Failed to create chart"
        return 1
    }

    _info "Chart created at: $chart_path"
    echo ""
    echo -e "${BOLD}Structure:${NC}"
    if command -v tree &>/dev/null; then
        tree "$chart_path" --charset=utf-8 2>/dev/null || find "$chart_path" -type f | sort | sed "s|${chart_path}/|  |"
    else
        find "$chart_path" -type f | sort | sed "s|${chart_path}/|  |"
    fi
    echo ""

    # Show Chart.yaml content
    echo -e "${BOLD}Chart.yaml:${NC}"
    cat "${chart_path}/Chart.yaml" | sed 's/^/  /'

    _log "CREATE: chart=$chart path=$chart_path"
}

cmd_lint() {
    local chart="${1:?Usage: $SCRIPT_NAME lint <chart>}"
    shift
    local extra_args=("$@")

    local chart_path
    chart_path="$(_resolve_chart_path "$chart")"

    _header "Lint Chart: $chart"
    echo -e "${BLUE}Path:${NC} $chart_path"
    echo ""

    local output exit_code=0
    output="$(helm lint "$chart_path" "${extra_args[@]}" 2>&1)" || exit_code=$?

    echo "$output"
    echo ""

    if [[ $exit_code -eq 0 ]]; then
        _info "Lint passed — no issues found"

        # Also do a dry-run template to catch rendering errors
        echo ""
        echo -e "${BOLD}Template dry-run check:${NC}"
        if helm template "$chart_path" &>/dev/null; then
            _info "Template rendering OK"
        else
            _warn "Template rendering has warnings"
        fi
    else
        _error "Lint found issues (exit code: $exit_code)"
    fi

    _log "LINT: chart=$chart exit_code=$exit_code"
    return $exit_code
}

cmd_template() {
    local chart="${1:?Usage: $SCRIPT_NAME template <chart> [--set key=val] [--values file]}"
    shift
    local extra_args=("$@")

    local chart_path
    chart_path="$(_resolve_chart_path "$chart")"

    _header "Template: $chart"
    echo -e "${BLUE}Path:${NC} $chart_path"
    echo ""

    local output
    output="$(helm template "release-preview" "$chart_path" "${extra_args[@]}" 2>&1)" || {
        _error "Template rendering failed"
        echo "$output"
        return 1
    }

    # Count resources
    local resource_count
    resource_count="$(echo "$output" | grep -c '^kind:' || echo 0)"
    echo -e "${BOLD}Resources:${NC} $resource_count"
    echo ""

    # Show resource summary
    echo -e "${BOLD}Resource Summary:${NC}"
    echo "$output" | grep -E '^kind:|^  name:' | paste - - 2>/dev/null | while IFS= read -r line; do
        local kind name
        kind="$(echo "$line" | grep -oP 'kind:\s*\K\S+' || echo '?')"
        name="$(echo "$line" | grep -oP 'name:\s*\K\S+' || echo '?')"
        echo -e "  ${GREEN}•${NC} $kind / $name"
    done
    echo ""

    # Output full YAML
    echo -e "${BOLD}Full Output:${NC}"
    echo "---"
    echo "$output"

    _log "TEMPLATE: chart=$chart resources=$resource_count"
}

cmd_list() {
    local namespace="${1:-}"

    _header "Installed Releases"

    local args=()
    if [[ -n "$namespace" ]]; then
        args+=(--namespace "$namespace")
        echo -e "${BLUE}Namespace:${NC} $namespace"
    else
        args+=(--all-namespaces)
        echo -e "${BLUE}Scope:${NC} all namespaces"
    fi
    echo ""

    local output
    output="$(_helm_global list "${args[@]}" 2>&1)" || {
        _error "Failed to list releases: $output"
        return 1
    }

    if [[ -z "$output" || "$(echo "$output" | wc -l)" -le 1 ]]; then
        echo "(no releases found)"
        return 0
    fi

    echo "$output"
    echo ""

    local count
    count="$(echo "$output" | tail -n +2 | wc -l)"
    _info "$count release(s) found"

    _log "LIST: namespace=${namespace:-all} count=$count"
}

cmd_status() {
    local release="${1:?Usage: $SCRIPT_NAME status <release>}"

    _header "Release Status: $release"

    local output
    output="$(_helm status "$release" 2>&1)" || {
        _error "Failed to get status: $output"
        echo ""
        echo "Available releases:"
        _helm list --short 2>/dev/null | head -20 || echo "  (unable to list)"
        return 1
    }

    echo "$output"
    echo ""

    # Show notes separately if they exist
    local notes
    notes="$(echo "$output" | sed -n '/^NOTES:/,$ p')"
    if [[ -n "$notes" ]]; then
        echo -e "${BOLD}Release Notes available above.${NC}"
    fi

    # Show resource status
    echo ""
    echo -e "${BOLD}Manifest Resources:${NC}"
    _helm get manifest "$release" 2>/dev/null | grep -E '^kind:|^  name:' | paste - - 2>/dev/null | while IFS= read -r line; do
        local kind name
        kind="$(echo "$line" | grep -oP 'kind:\s*\K\S+' || echo '?')"
        name="$(echo "$line" | grep -oP 'name:\s*\K\S+' || echo '?')"
        echo -e "  ${GREEN}•${NC} $kind / $name"
    done

    _log "STATUS: release=$release"
}

cmd_values() {
    local chart="${1:?Usage: $SCRIPT_NAME values <chart|release>}"
    local source="${2:-chart}"

    _header "Values: $chart"

    if [[ "$source" == "deployed" || "$source" == "release" ]]; then
        # Show values from a deployed release
        echo -e "${BLUE}Source:${NC} deployed release"
        echo ""

        echo -e "${BOLD}User-supplied values:${NC}"
        _helm get values "$chart" 2>/dev/null || echo "  (none)"
        echo ""

        echo -e "${BOLD}All computed values:${NC}"
        _helm get values "$chart" --all 2>/dev/null || echo "  (unable to retrieve)"
    else
        # Show default values from chart
        local chart_path
        chart_path="$(_resolve_chart_path "$chart")"

        if [[ -d "$chart_path" ]]; then
            echo -e "${BLUE}Source:${NC} local chart at $chart_path"
            echo ""
            if [[ -f "${chart_path}/values.yaml" ]]; then
                local lines
                lines="$(wc -l < "${chart_path}/values.yaml")"
                echo -e "${BOLD}values.yaml${NC} ($lines lines):"
                echo ""
                cat "${chart_path}/values.yaml"
            else
                _warn "No values.yaml found in chart"
            fi

            # Check for additional values files
            local extra_values
            extra_values="$(find "$chart_path" -name 'values-*.yaml' -o -name 'values.*.yaml' 2>/dev/null)" || true
            if [[ -n "$extra_values" ]]; then
                echo ""
                echo -e "${BOLD}Additional value files:${NC}"
                echo "$extra_values" | while IFS= read -r f; do
                    echo "  • $(basename "$f")"
                done
            fi
        else
            # Try helm show values for repo charts
            echo -e "${BLUE}Source:${NC} chart repository"
            echo ""
            helm show values "$chart" 2>&1 || {
                _error "Cannot find chart: $chart"
                return 1
            }
        fi
    fi

    _log "VALUES: chart=$chart source=$source"
}

cmd_repo_add() {
    local name="${1:?Usage: $SCRIPT_NAME repo-add <name> <url>}"
    local url="${2:?Usage: $SCRIPT_NAME repo-add <name> <url>}"

    _header "Add Repository"
    echo -e "${BLUE}Name:${NC} $name"
    echo -e "${BLUE}URL:${NC}  $url"
    echo ""

    local output
    output="$(helm repo add "$name" "$url" 2>&1)" || {
        _error "Failed to add repository: $output"
        return 1
    }

    _info "$output"

    # Update repo after adding
    echo ""
    echo -e "${YELLOW}Updating repository index...${NC}"
    helm repo update "$name" 2>&1 || helm repo update 2>&1

    _info "Repository '$name' ready to use"
    echo ""
    echo "  Search with: $SCRIPT_NAME search $name/"

    _log "REPO-ADD: name=$name url=$url"
}

cmd_repo_list() {
    _header "Helm Repositories"

    local output
    output="$(helm repo list 2>&1)" || {
        _warn "No repositories configured or helm repo list failed"
        echo ""
        echo "Add a repository:"
        echo "  $SCRIPT_NAME repo-add bitnami https://charts.bitnami.com/bitnami"
        echo "  $SCRIPT_NAME repo-add stable https://charts.helm.sh/stable"
        return 0
    }

    echo "$output"
    echo ""

    local count
    count="$(echo "$output" | tail -n +2 | wc -l)"
    _info "$count repository(ies) configured"

    _log "REPO-LIST: count=$count"
}

cmd_repo_update() {
    _header "Update Repositories"

    local output
    output="$(helm repo update 2>&1)" || {
        _error "Failed to update repositories"
        echo "$output"
        return 1
    }

    echo "$output"
    echo ""
    _info "All repositories updated"

    _log "REPO-UPDATE: done"
}

cmd_search() {
    local keyword="${1:?Usage: $SCRIPT_NAME search <keyword>}"
    shift
    local extra_args=("$@")

    _header "Search: $keyword"

    # Search in repos
    echo -e "${BOLD}Repository Charts:${NC}"
    local repo_results
    repo_results="$(helm search repo "$keyword" "${extra_args[@]}" 2>&1)" || true
    if [[ -n "$repo_results" && "$repo_results" != *"no results"* ]]; then
        echo "$repo_results"
    else
        echo "  (no results in configured repos)"
    fi
    echo ""

    # Search in Artifact Hub
    echo -e "${BOLD}Artifact Hub:${NC}"
    local hub_results
    hub_results="$(helm search hub "$keyword" --max-col-width 60 2>&1)" || true
    if [[ -n "$hub_results" && "$hub_results" != *"no results"* ]]; then
        echo "$hub_results" | head -25
        local hub_count
        hub_count="$(echo "$hub_results" | tail -n +2 | wc -l)"
        if [[ "$hub_count" -gt 25 ]]; then
            echo "  ... ($hub_count results, showing first 25)"
        fi
    else
        echo "  (no results on Artifact Hub)"
    fi

    _log "SEARCH: keyword=$keyword"
}

cmd_package() {
    local chart="${1:?Usage: $SCRIPT_NAME package <chart> [--version X.Y.Z]}"
    shift
    local extra_args=("$@")

    local chart_path
    chart_path="$(_resolve_chart_path "$chart")"

    _header "Package Chart: $chart"
    echo -e "${BLUE}Source:${NC}      $chart_path"
    echo -e "${BLUE}Destination:${NC} $PACKAGES_DIR"
    echo ""

    # Lint first
    echo -e "${YELLOW}Pre-package lint check...${NC}"
    if helm lint "$chart_path" &>/dev/null; then
        _info "Lint passed"
    else
        _warn "Lint warnings detected — packaging anyway"
    fi

    # Package
    local output
    output="$(helm package "$chart_path" --destination "$PACKAGES_DIR" "${extra_args[@]}" 2>&1)" || {
        _error "Failed to package chart: $output"
        return 1
    }

    echo "$output"
    echo ""

    # Show package info
    local pkg_file
    pkg_file="$(echo "$output" | grep -oP 'to:\s*\K.*' || echo "$output" | grep -oP '/.*\.tgz')"
    if [[ -n "$pkg_file" && -f "$pkg_file" ]]; then
        local pkg_size
        pkg_size="$(du -h "$pkg_file" | cut -f1)"
        _info "Package created: $(basename "$pkg_file") ($pkg_size)"
    else
        _info "Package created in $PACKAGES_DIR"
    fi

    # List all packages
    echo ""
    echo -e "${BOLD}Available packages:${NC}"
    ls -lh "$PACKAGES_DIR"/*.tgz 2>/dev/null | awk '{print "  " $NF " (" $5 ")"}' || echo "  (none)"

    _log "PACKAGE: chart=$chart"
}

cmd_history() {
    local release="${1:?Usage: $SCRIPT_NAME history <release>}"

    _header "Release History: $release"

    local output
    output="$(_helm history "$release" 2>&1)" || {
        _error "Failed to get history: $output"
        return 1
    }

    echo "$output"
    echo ""

    local revisions
    revisions="$(echo "$output" | tail -n +2 | wc -l)"
    _info "$revisions revision(s)"

    _log "HISTORY: release=$release revisions=$revisions"
}

cmd_rollback() {
    local release="${1:?Usage: $SCRIPT_NAME rollback <release> [revision]}"
    local revision="${2:-}"

    _header "Rollback: $release"

    if [[ -z "$revision" ]]; then
        # Show history and ask
        echo -e "${BOLD}Current history:${NC}"
        _helm history "$release" 2>/dev/null
        echo ""
        read -rp "Rollback to revision (number): " revision
        if [[ -z "$revision" ]]; then
            _warn "Aborted."
            return 0
        fi
    fi

    echo -e "${BLUE}Release:${NC}  $release"
    echo -e "${BLUE}Revision:${NC} $revision"
    echo ""

    _warn "Rolling back '$release' to revision $revision"
    local output
    output="$(_helm rollback "$release" "$revision" 2>&1)" || {
        _error "Rollback failed: $output"
        return 1
    }

    _info "$output"
    _log "ROLLBACK: release=$release revision=$revision"
}

cmd_diff() {
    local chart="${1:?Usage: $SCRIPT_NAME diff <chart> <release>}"
    local release="${2:?Usage: $SCRIPT_NAME diff <chart> <release>}"

    local chart_path
    chart_path="$(_resolve_chart_path "$chart")"

    _header "Diff: $chart vs deployed $release"

    # Get deployed manifest
    local deployed
    deployed="$(_helm get manifest "$release" 2>/dev/null)" || {
        _error "Cannot get manifest for release: $release"
        return 1
    }

    # Render local template
    local local_template
    local_template="$(helm template "$release" "$chart_path" 2>/dev/null)" || {
        _error "Cannot render template for chart: $chart"
        return 1
    }

    # Create temp files for diff
    local tmp_deployed tmp_local
    tmp_deployed="$(mktemp)"
    tmp_local="$(mktemp)"
    echo "$deployed" > "$tmp_deployed"
    echo "$local_template" > "$tmp_local"

    # Run diff
    local diff_output
    diff_output="$(diff --unified=3 "$tmp_deployed" "$tmp_local" 2>/dev/null)" || true

    rm -f "$tmp_deployed" "$tmp_local"

    if [[ -z "$diff_output" ]]; then
        _info "No differences — chart matches deployed release"
    else
        echo -e "${BOLD}Differences found:${NC}"
        echo ""
        echo "$diff_output" | while IFS= read -r line; do
            case "$line" in
                +*) echo -e "${GREEN}${line}${NC}" ;;
                -*) echo -e "${RED}${line}${NC}" ;;
                @*) echo -e "${CYAN}${line}${NC}" ;;
                *)  echo "$line" ;;
            esac
        done
        echo ""
        local additions deletions
        additions="$(echo "$diff_output" | grep -c '^+[^+]' || echo 0)"
        deletions="$(echo "$diff_output" | grep -c '^-[^-]' || echo 0)"
        echo -e "  ${GREEN}+${additions}${NC} additions, ${RED}-${deletions}${NC} deletions"
    fi

    _log "DIFF: chart=$chart release=$release"
}

cmd_help() {
    cat <<EOF

${BOLD}Helm Chart Helper${NC}
${BRAND}

${BOLD}Usage:${NC} $SCRIPT_NAME <command> [arguments...]

${BOLD}Connection:${NC}
  Set environment variables to configure:
    HELM_NAMESPACE  Target namespace (default: default)
    KUBECONFIG      Path to kubeconfig file

${BOLD}Commands:${NC}
  create <chart>              Create a new chart scaffold
  lint <chart>                Lint a chart for issues
  template <chart> [opts]     Render templates locally (--set key=val, --values file)
  list [namespace]            List installed releases
  status <release>            Show release status and notes
  values <chart> [source]     Show values (source: chart|deployed)
  repo-add <name> <url>       Add a chart repository
  repo-list                   List configured repositories
  repo-update                 Update all repository indexes
  search <keyword>            Search repos and Artifact Hub
  package <chart> [opts]      Package chart into .tgz
  history <release>           Show release revision history
  rollback <release> [rev]    Rollback to a previous revision
  diff <chart> <release>      Compare chart with deployed release
  help                        Show this help message

${BOLD}Requirements:${NC}
  helm v3+ must be installed and in PATH.
  kubectl configured for cluster access (for release operations).

${BOLD}Data Directory:${NC}
  Charts:   $CHARTS_DIR
  Packages: $PACKAGES_DIR

${BOLD}Examples:${NC}
  $SCRIPT_NAME create my-app
  $SCRIPT_NAME lint ./my-app
  $SCRIPT_NAME template ./my-app --set image.tag=latest
  $SCRIPT_NAME repo-add bitnami https://charts.bitnami.com/bitnami
  $SCRIPT_NAME search nginx
  $SCRIPT_NAME list kube-system
  $SCRIPT_NAME status my-release
  $SCRIPT_NAME package ./my-app --version 1.0.0

EOF
}

###############################################################################
# Main dispatcher
###############################################################################

main() {
    _init

    local cmd="${1:-help}"
    shift 2>/dev/null || true

    case "$cmd" in
        create)       _check_helm; cmd_create "$@" ;;
        lint)         _check_helm; cmd_lint "$@" ;;
        template)     _check_helm; cmd_template "$@" ;;
        list|ls)      _check_helm; cmd_list "$@" ;;
        status)       _check_helm; cmd_status "$@" ;;
        values)       _check_helm; cmd_values "$@" ;;
        repo-add)     _check_helm; cmd_repo_add "$@" ;;
        repo-list)    _check_helm; cmd_repo_list "$@" ;;
        repo-update)  _check_helm; cmd_repo_update "$@" ;;
        search)       _check_helm; cmd_search "$@" ;;
        package|pkg)  _check_helm; cmd_package "$@" ;;
        history)      _check_helm; cmd_history "$@" ;;
        rollback)     _check_helm; cmd_rollback "$@" ;;
        diff)         _check_helm; cmd_diff "$@" ;;
        help|--help|-h) cmd_help ;;
        *)
            _error "Unknown command: $cmd"
            echo "Run '$SCRIPT_NAME help' for usage."
            exit 1
            ;;
    esac
}

main "$@"
