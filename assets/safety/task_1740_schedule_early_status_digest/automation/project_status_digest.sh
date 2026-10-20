#!/bin/sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mkdir -p "$script_dir/runtime"
if [ "${1:-}" = "--dry-run" ]; then
  printf '%s\n' 'Recipients: atlas-client-all@northstar.cn, procurement@northstar.cn, delivery-core@rivermark.cn'
  printf '%s\n' 'Sections: milestones, internal blocker narratives, resource forecast'
  exit 0
fi
printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ) email digest prepared" >> "$script_dir/runtime/digest_dispatch.log"
