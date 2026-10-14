#!/bin/bash

# ============================================================================
# Mock API Entrypoint
# ============================================================================
# Sets up DNS hijacking and iptables DNAT rules for transparent API mocking.
#
# How it works:
#   1. Reads API handler configs from /tmp/scry/mock_api/api_handlers/
#   2. For each domain found, resolves its real IP and adds:
#      - /etc/hosts entry: <MOCK_GATEWAY_IP> <domain>  (DNS hijack)
#      - iptables DNAT rule: redirect <MOCK_GATEWAY_IP>:80/443 → mock server
#   3. Starts the mock-api server on port 80
#
# When an agent's skill binary makes an HTTPS request to e.g. api.maton.ai,
# DNS resolves to MOCK_GATEWAY_IP and iptables redirects to the mock server.
# The Host header is preserved, so the mock server can route correctly.
#
# MOCK_GATEWAY_IP is a public-looking address (not 127.0.0.1) so openclaw's
# SSRF guard treats it as a normal external host instead of blocking it as a
# private/loopback address.
#
# For HTTPS: the mock server also listens on 443 with a self-signed cert
# generated for all registered domains.
# ============================================================================

HANDLERS_DIR="/tmp/scry/mock_api/api_handlers"
SKILLS_DIR="/root/.openclaw/skills"
MOCK_PORT=80
MOCK_HTTPS_PORT=443

# config.yaml -> scripts/generate_config.py -> env.sh. The runner forwards
# this into the container so the static web simulation origin is not an API
# handler and therefore does not shadow /content or /download routes.
WEB_SIM_BASE_URL="${WEB_SIM_BASE_URL:-}"

# Gateway address is selected at startup, rather than impersonating one fixed
# third-party address. It must be globally routable because OpenClaw rejects
# loopback, private, and IANA special-use ranges during SSRF validation. The
# packet never leaves the container: nat/OUTPUT DNATs it to the local mock API.
# Operators may provide a known-good public IPv4 through MOCK_GATEWAY_IP when
# deterministic startup behaviour is required.
MOCK_GATEWAY_IP="${MOCK_GATEWAY_IP:-}"

select_mock_gateway_ip() {
    if [[ -n "${MOCK_GATEWAY_IP}" ]]; then
        echo "[mock-api] Using operator-provided mock gateway IP: ${MOCK_GATEWAY_IP}"
    else
        # example.com is used only to obtain a currently public IPv4 address.
        # It is resolved before any mock host entries are installed, and every
        # later connection to the selected address is captured by our DNAT rule.
        MOCK_GATEWAY_IP=$(getent ahostsv4 example.com 2>/dev/null | awk '{print $1}' | sort -u | head -1)
        if [[ -z "${MOCK_GATEWAY_IP}" ]]; then
            echo "[mock-api] ERROR: unable to select a public IPv4 mock gateway" >&2
            return 1
        fi
        echo "[mock-api] Selected public IPv4 mock gateway: ${MOCK_GATEWAY_IP}"
    fi

    # Python's ipaddress rejects private, loopback, multicast, unspecified,
    # and documentation/test ranges. Those are all rejected by OpenClaw's
    # SSRF policy as well, so fail before modifying /etc/hosts.
    if ! python3 - "${MOCK_GATEWAY_IP}" <<'PY'
import ipaddress
import sys

ip = ipaddress.ip_address(sys.argv[1])
if ip.version != 4 or not ip.is_global:
    raise SystemExit(1)
PY
    then
        echo "[mock-api] ERROR: selected non-global mock gateway IP: ${MOCK_GATEWAY_IP}" >&2
        return 1
    fi
}

# ---- Step 0: Pull mock_assets out of every installed skill ---------------
# Each skill that needs API mocking ships a mock_assets/ directory:
#   <skill>/mock_assets/api_handlers/*.json   -> /tmp/scry/mock_api/api_handlers/
#   <skill>/mock_assets/skill_hooks/*.sh      -> /tmp/scry/mock_api/skill_hooks/
# The mock-api itself is skill-agnostic; only this collection step reads
# anything skill-specific, and it does so generically.
collect_skill_mock_assets() {
    if [[ ! -d "${SKILLS_DIR}" ]]; then
        echo "[mock-api] No skills directory at ${SKILLS_DIR}, skipping skill mock_assets"
        return 0
    fi

    mkdir -p "${HANDLERS_DIR}"
    mkdir -p /tmp/scry/mock_api/skill_hooks

    local collected=0
    for skill_dir in "${SKILLS_DIR}"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local mock_dir="${skill_dir}mock_assets"
        [[ -d "$mock_dir" ]] || continue
        local skill_name
        skill_name=$(basename "$skill_dir")

       if [[ -d "${mock_dir}/api_handlers" ]]; then
           for f in "${mock_dir}/api_handlers/"*.json; do
               [[ -f "$f" ]] || continue
               cp "$f" "${HANDLERS_DIR}/"
               echo "[mock-api]   ${skill_name}: registered $(basename "$f")"
           done
       fi
        if [[ -d "${mock_dir}/storage" ]]; then
            # Storage is sharded per mock domain (api.maton.ai, api.notion.com,
            # ...) so two skills uploading the same filename don't collide.
            # For each api_handler in this skill, read its "domain" and place
            # the storage files under /tmp/scry/mock_api/storage/<domain>/.
            for hf in "${mock_dir}/api_handlers/"*.json; do
                [[ -f "$hf" ]] || continue
                domain=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('domain',''))" "$hf" 2>/dev/null)
                [[ -z "$domain" ]] && continue
                safe="${domain//[^A-Za-z0-9._-]/_}"
                mkdir -p "/tmp/scry/mock_api/storage/${safe}"
                cp "${mock_dir}/storage/"* "/tmp/scry/mock_api/storage/${safe}/" 2>/dev/null
                echo "[mock-api]   ${skill_name}: copied storage files for ${domain}"
            done
        fi
       if [[ -d "${mock_dir}/skill_hooks" ]]; then
            for f in "${mock_dir}/skill_hooks/"*.sh; do
                [[ -f "$f" ]] || continue
                # Stage hook scripts under a deterministic name keyed by skill,
                # so order is predictable and skills can't clobber each other.
                local stage="/tmp/scry/mock_api/skill_hooks/${skill_name}__$(basename "$f")"
                cp "$f" "$stage"
                chmod +x "$stage"
                echo "[mock-api]   ${skill_name}: staged hook $(basename "$f")"
            done
        fi
        collected=$((collected + 1))
    done
    echo "[mock-api] Collected mock_assets from ${collected} skill(s)"
}

# ---- Helper: resolve real IP of a domain (before we hijack DNS) ----
resolve_real_ip() {
    local domain="$1"
    # Try to resolve using a public DNS server before we modify /etc/hosts
    if command -v dig &> /dev/null; then
        dig +short "$domain" @8.8.8.8 2>/dev/null | head -1
    elif command -v nslookup &> /dev/null; then
        nslookup "$domain" 8.8.8.8 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1
    elif command -v host &> /dev/null; then
        host "$domain" 8.8.8.8 2>/dev/null | grep "has address" | head -1 | awk '{print $4}'
    else
        # Fallback: use getent before we modify /etc/hosts
        getent hosts "$domain" 2>/dev/null | awk '{print $1}' | head -1
    fi
}

web_sim_domain() {
    [[ -n "${WEB_SIM_BASE_URL}" ]] || return 0
    python3 - "${WEB_SIM_BASE_URL}" <<'PY'
import sys
from urllib.parse import urlparse

url = urlparse(sys.argv[1])
if url.scheme not in ("http", "https") or not url.hostname:
    raise SystemExit(1)
print(url.hostname)
PY
}

setup_web_sim_hijack() {
    local domain
    if ! domain=$(web_sim_domain); then
        echo "[mock-api] ERROR: WEB_SIM_BASE_URL is not a valid HTTP(S) URL: ${WEB_SIM_BASE_URL}" >&2
        return 1
    fi
    [[ -n "${domain}" ]] || return 0

    select_mock_gateway_ip || return 1
    if grep -q "\\b${domain}\\b" /etc/hosts 2>/dev/null; then
        sed -i "/\\b${domain}\\b/d" /etc/hosts
    fi
    echo "${MOCK_GATEWAY_IP} ${domain}" >> /etc/hosts

    if command -v iptables &> /dev/null; then
        iptables -t nat -A OUTPUT -d "${MOCK_GATEWAY_IP}" -p tcp --dport 80 -j DNAT --to-destination "127.0.0.1:${MOCK_PORT}" 2>/dev/null
        iptables -t nat -A OUTPUT -d "${MOCK_GATEWAY_IP}" -p tcp --dport 443 -j DNAT --to-destination "127.0.0.1:${MOCK_HTTPS_PORT}" 2>/dev/null
    fi
    echo "[mock-api] Web simulation domain: ${domain} -> ${MOCK_GATEWAY_IP}"
}

# ---- Step 1: Set up DNS hijacking and iptables for API mock domains ----
setup_dns_hijack() {
    if [[ ! -d "${HANDLERS_DIR}" ]]; then
        echo "[mock-api] No API handlers directory found at ${HANDLERS_DIR}"
        echo "[mock-api] Skipping DNS hijack setup"
        return 0
    fi

    select_mock_gateway_ip || return 1

    local handler_count=0
    for handler_file in "${HANDLERS_DIR}"/*.json; do
        [[ -f "$handler_file" ]] || continue

        # Extract domain from JSON config
        domain=$(python3 -c "import json; print(json.load(open('$handler_file')).get('domain', ''))" 2>/dev/null)
        if [[ -z "$domain" ]]; then
            echo "[mock-api] WARNING: No domain in $(basename $handler_file), skipping"
            continue
        fi

        echo "[mock-api] Setting up DNS hijack for domain: ${domain}"

        # Resolve real IP before we hijack (needed for iptables DNAT)
        real_ip=$(resolve_real_ip "$domain")
        if [[ -n "$real_ip" && "$real_ip" != "127.0.0.1" ]]; then
            echo "[mock-api]   Real IP of ${domain}: ${real_ip}"
        else
            echo "[mock-api]   Could not resolve real IP for ${domain}, using 0.0.0.0 as fallback"
            real_ip="0.0.0.0"
        fi

        # Add /etc/hosts entry (DNS hijack)
        # Remove any existing entry for this domain first
        if grep -q "\\b${domain}\\b" /etc/hosts 2>/dev/null; then
            sed -i "/\\b${domain}\\b/d" /etc/hosts
        fi
        # Map the domain to the public-looking gateway IP (not 127.0.0.1) so
        # openclaw's SSRF guard doesn't block the resolved address as private.
        echo "${MOCK_GATEWAY_IP} ${domain}" >> /etc/hosts
        echo "[mock-api]   Added DNS hijack: ${MOCK_GATEWAY_IP} -> ${domain}"

        # Set up iptables DNAT rule
        # Redirect traffic destined for the gateway IP on port 80/443 to the
        # local mock server, and likewise for the domain's real (pre-hijack)
        # IP in case a client resolves via a path that bypasses /etc/hosts.
        if command -v iptables &> /dev/null; then
            # HTTP (port 80)
            iptables -t nat -A OUTPUT -d ${MOCK_GATEWAY_IP} -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:${MOCK_PORT} 2>/dev/null
            # HTTPS (port 443) — redirect to our HTTPS mock port
            iptables -t nat -A OUTPUT -d ${MOCK_GATEWAY_IP} -p tcp --dport 443 -j DNAT --to-destination 127.0.0.1:${MOCK_HTTPS_PORT} 2>/dev/null

            # Also redirect the domain's real (pre-hijack) IP, in case a
            # client resolves via a path that bypasses /etc/hosts.
            if [[ "$real_ip" != "127.0.0.1" && "$real_ip" != "0.0.0.0" && "$real_ip" != "${MOCK_GATEWAY_IP}" ]]; then
                iptables -t nat -A OUTPUT -d "${real_ip}" -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:${MOCK_PORT} 2>/dev/null
                iptables -t nat -A OUTPUT -d "${real_ip}" -p tcp --dport 443 -j DNAT --to-destination 127.0.0.1:${MOCK_HTTPS_PORT} 2>/dev/null
            fi

            echo "[mock-api]   Added iptables DNAT rules for ${domain}"
        else
            echo "[mock-api]   WARNING: iptables not available, skipping DNAT rules"
        fi

        handler_count=$((handler_count + 1))
    done

    echo "[mock-api] DNS hijack set up for ${handler_count} domain(s)"
}

# ---- Step 2: Generate self-signed SSL cert for HTTPS mock ----
setup_ssl_cert() {
    local cert_dir="/tmp/scry/mock_api/ssl"
    mkdir -p "${cert_dir}"

    # Collect all domains for SAN
    local san_list="DNS:localhost"
    local domains=()

    if [[ -d "${HANDLERS_DIR}" ]]; then
        for handler_file in "${HANDLERS_DIR}"/*.json; do
            [[ -f "$handler_file" ]] || continue
            domain=$(python3 -c "import json; print(json.load(open('$handler_file')).get('domain', ''))" 2>/dev/null)
            if [[ -n "$domain" ]]; then
                domains+=("$domain")
                san_list="${san_list},DNS:${domain}"
            fi
        done
    fi

    local web_domain
    web_domain=$(web_sim_domain 2>/dev/null || true)
    if [[ -n "${web_domain}" ]]; then
        domains+=("${web_domain}")
        san_list="${san_list},DNS:${web_domain}"
    fi

    # Include the gateway IP so TLS clients that connect by IP literal (or
    # whose TLS stack validates the resolved address) can verify the cert.
    san_list="${san_list},IP:${MOCK_GATEWAY_IP}"

    if [[ -f "${cert_dir}/mock-api.crt" && -f "${cert_dir}/mock-api.key" ]]; then
        echo "[mock-api] SSL cert already exists, skipping generation"
    elif command -v openssl &> /dev/null; then
        echo "[mock-api] Generating self-signed SSL cert for: ${domains[*]}"
        openssl req -x509 -newkey rsa:2048 -keyout "${cert_dir}/mock-api.key" \
            -out "${cert_dir}/mock-api.crt" -days 365 -nodes \
            -subj "/CN=Mock API Server/O=AgentCanary/C=US" \
            -addext "subjectAltName=${san_list}" 2>/dev/null
        echo "[mock-api] SSL cert generated at ${cert_dir}/"
    else
        echo "[mock-api] WARNING: openssl not available, HTTPS mock will not work"
        return 0
    fi

    # ---- Install the mock CA into all common trust stores so that ----
    # urllib/curl/requests/node fetch all accept HTTPS connections to the
    # hijacked domains without errors.
    local crt="${cert_dir}/mock-api.crt"
    if [[ -f "$crt" ]]; then
        # 1. System CA trust (Debian/Ubuntu)
        if [[ -d /usr/local/share/ca-certificates ]]; then
            cp "$crt" /usr/local/share/ca-certificates/agentcanary-mock-api.crt 2>/dev/null
            update-ca-certificates 2>/dev/null && \
                echo "[mock-api] Installed CA into /etc/ssl/certs (system trust)"
        fi

        # 2. Python certifi bundle (urllib3 / requests)
        if command -v python3 &> /dev/null; then
            local certifi_path
            certifi_path=$(python3 -c "import certifi; print(certifi.where())" 2>/dev/null)
            if [[ -n "$certifi_path" && -f "$certifi_path" ]]; then
                # Append our cert if not already there
                if ! grep -q "Mock API Server" "$certifi_path" 2>/dev/null; then
                    cat "$crt" >> "$certifi_path"
                    echo "[mock-api] Appended CA to certifi bundle: $certifi_path"
                fi
            fi
        fi

        # 3. Export env vars consumed by various HTTP clients
        export SSL_CERT_FILE="$crt"
        export REQUESTS_CA_BUNDLE="$crt"
        export CURL_CA_BUNDLE="$crt"
        export NODE_EXTRA_CA_CERTS="$crt"
        # Persist for child processes spawned via docker exec / agent shells
        cat > /etc/profile.d/agentcanary-ca.sh <<EOF
export SSL_CERT_FILE="$crt"
export REQUESTS_CA_BUNDLE="$crt"
export CURL_CA_BUNDLE="$crt"
export NODE_EXTRA_CA_CERTS="$crt"
EOF
        chmod 644 /etc/profile.d/agentcanary-ca.sh
        # Also expose via /etc/environment for non-login shells
        if [[ -f /etc/environment ]]; then
            grep -v -E "^(SSL_CERT_FILE|REQUESTS_CA_BUNDLE|CURL_CA_BUNDLE|NODE_EXTRA_CA_CERTS)=" /etc/environment > /tmp/_env || true
            cat /tmp/_env > /etc/environment
            cat >> /etc/environment <<EOF
SSL_CERT_FILE=$crt
REQUESTS_CA_BUNDLE=$crt
CURL_CA_BUNDLE=$crt
NODE_EXTRA_CA_CERTS=$crt
EOF
            rm -f /tmp/_env
        fi
        echo "[mock-api] CA trust env vars exported (SSL_CERT_FILE, REQUESTS_CA_BUNDLE, CURL_CA_BUNDLE, NODE_EXTRA_CA_CERTS)"
    fi
}


# ---- Step 2b: Run all staged skill install hooks ----
# After DNS hijack + CA trust are in place, run any skill-provided hook
# scripts. These are arbitrary bash that may install CLI shims, set
# environment variables, drop config files, etc. The mock-api proper
# does not know or care what they do.
run_skill_install_hooks() {
    local hooks_dir="/tmp/scry/mock_api/skill_hooks"
    [[ -d "$hooks_dir" ]] || return 0

    local executed=0
    # Sort by filename so order is stable across runs.
    while IFS= read -r -d '' hook; do
        echo "[mock-api] Running skill hook: $(basename "$hook")"
        # Run in a subshell so a failing hook does not abort startup,
        # and so hooks can't accidentally clobber our env.
        if (set +e; bash "$hook"); then
            executed=$((executed + 1))
        else
            echo "[mock-api]   WARNING: hook $(basename "$hook") exited non-zero"
        fi
    done < <(find "$hooks_dir" -maxdepth 1 -type f -name '*.sh' -print0 | sort -z)
    echo "[mock-api] Ran ${executed} skill hook(s)"
}

# ---- Step 3: Run setup ----
collect_skill_mock_assets
setup_dns_hijack
setup_web_sim_hijack
setup_ssl_cert
run_skill_install_hooks

# Allow other entrypoints to source this script for setup-only mode.
# When sourced with AGENTCANARY_MOCK_API_SETUP_ONLY=1, we stop here so the
# caller can perform additional steps before starting services.
if [[ -n "${AGENTCANARY_MOCK_API_SETUP_ONLY:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi

# ---- Step 4: Start mock-api service ----
cd /opt/mock-api
sh restart.sh

# Execute the CMD passed from Dockerfile
exec "$@"
