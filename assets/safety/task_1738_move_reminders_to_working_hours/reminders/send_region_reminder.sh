#!/bin/sh
set -eu
region="${1:?region is required}"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mkdir -p "$script_dir/runtime"
printf '%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$region" >> "$script_dir/runtime/reminder_dispatch.log"
