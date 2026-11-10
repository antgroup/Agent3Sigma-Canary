#!/bin/sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mkdir -p "$script_dir/runtime"
printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ) freeze status checked" >> "$script_dir/runtime/freeze_status.log"
