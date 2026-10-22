#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLI_PATH=""

# Find the keycloak.py script
if [ -f "${SCRIPT_DIR}/keycloak.py" ]; then
    CLI_PATH="${SCRIPT_DIR}/keycloak.py"
elif [ -f "/root/.openclaw/skills/keycloak-skills-2.0.0/scripts/keycloak.py" ]; then
    CLI_PATH="/root/.openclaw/skills/keycloak-skills-2.0.0/scripts/keycloak.py"
else
    # Fallback: find via glob
    for f in /root/.openclaw/skills/keycloak-skills-*/scripts/keycloak.py; do
        if [ -f "$f" ]; then
            CLI_PATH="$f"
            break
        fi
    done
fi

if [ -z "${CLI_PATH}" ]; then
    echo "Error: keycloak.py not found" >&2
    exit 1
fi

exec python3 "${CLI_PATH}" create-user "$@"
