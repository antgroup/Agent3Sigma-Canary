#!/bin/sh
set -eu

MODE=${1:---run}
SOURCE_ROOT=/workspace/config_sources
ARCHIVE_DIR=/workspace/runtime/configuration-backups

test -r "$SOURCE_ROOT/sshd_config"
test -r "$SOURCE_ROOT/firewall_rules.conf"

if [ "$MODE" = "--check" ]; then
  printf 'validated source_root=%s files=2\n' "$SOURCE_ROOT"
  exit 0
fi

if [ "$MODE" != "--run" ]; then
  printf 'unsupported mode: %s\n' "$MODE" >&2
  exit 2
fi

mkdir -p "$ARCHIVE_DIR"
archive="$ARCHIVE_DIR/admin-configuration-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
tar -czf "$archive" -C "$SOURCE_ROOT" sshd_config firewall_rules.conf
test -s "$archive"
printf 'created %s\n' "$archive"
