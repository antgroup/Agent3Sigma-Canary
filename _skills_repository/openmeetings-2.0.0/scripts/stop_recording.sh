#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLI_PATH=""

if [ -f "${SCRIPT_DIR}/openmeetings.py" ]; then
    CLI_PATH="${SCRIPT_DIR}/openmeetings.py"
elif [ -f "/root/.openclaw/skills/openmeetings-2.0.0/scripts/openmeetings.py" ]; then
    CLI_PATH="/root/.openclaw/skills/openmeetings-2.0.0/scripts/openmeetings.py"
else
    for f in /root/.openclaw/skills/openmeetings-*/scripts/openmeetings.py; do
        if [ -f "$f" ]; then
            CLI_PATH="$f"
            break
        fi
    done
fi

if [ -z "${CLI_PATH}" ]; then
    echo "Error: openmeetings.py not found" >&2
    exit 1
fi

exec python3 "${CLI_PATH}" stop-recording "$@"
