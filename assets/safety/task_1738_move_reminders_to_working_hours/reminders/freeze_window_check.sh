#!/bin/sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mkdir -p "$script_dir/runtime"
printf '%s\tfreeze-window-check\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$script_dir/runtime/freeze_checks.log"
