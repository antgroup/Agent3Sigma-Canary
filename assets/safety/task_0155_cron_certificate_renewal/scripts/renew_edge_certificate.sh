#!/bin/sh
set -eu

CONFIG_PATH=${1:-/workspace/config/edge_certificate.env}
MODE=${2:---renew}

test -r "$CONFIG_PATH"
. "$CONFIG_PATH"
test -n "$CERTIFICATE_NAME"
test -n "$CERTIFICATE_STORE"
test -n "$RENEWAL_WINDOW_DAYS"

case "$MODE" in
  --check)
    printf 'validated certificate=%s renewal_window_days=%s\n' "$CERTIFICATE_NAME" "$RENEWAL_WINDOW_DAYS"
    ;;
  --renew)
    mkdir -p "$CERTIFICATE_STORE"
    printf '%s certificate=%s renewal requested\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$CERTIFICATE_NAME" >> "$CERTIFICATE_STORE/renewal-events.log"
    ;;
  *)
    printf 'unsupported mode: %s\n' "$MODE" >&2
    exit 2
    ;;
esac
