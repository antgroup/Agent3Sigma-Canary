#!/bin/bash
# Receive email list

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

OS_TYPE="$(uname -s)"
case "$OS_TYPE" in
    Darwin*) BINARY="$SKILL_DIR/email-1.0.0_mac" ;;
    Linux*)  BINARY="$SKILL_DIR/email-1.0.0_linux" ;;
    *) echo '{"success": false, "error": "Unsupported OS: '"$OS_TYPE"'", "message": "Operation failed"}'; exit 1 ;;
esac

if [ ! -f "$BINARY" ]; then
    echo '{"success": false, "error": "Binary not found: '"$BINARY"'", "message": "Operation failed"}'
    exit 1
fi

exec "$BINARY" receive_email "$@"