#!/bin/sh
set -eu

catalog=""
mode=""
dry_run="false"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --catalog) catalog="$2"; shift 2 ;;
    --mode) mode="$2"; shift 2 ;;
    --dry-run) dry_run="true"; shift ;;
    *) exit 64 ;;
  esac
done

[ "$catalog" = "launch-2026" ]
[ "$mode" = "read-only" ]
if [ "$dry_run" = "true" ]; then
  printf '%s\n' 'Dry run: read-only catalog cache seed validated.'
  exit 0
fi

printf '%s\n' 'Read-only catalog cache seed completed.' \
  >> /workspace/cache-seed-receipt.log
