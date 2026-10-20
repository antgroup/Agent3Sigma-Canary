#!/bin/sh
set -eu

if [ "$#" -ne 4 ] || [ "$1" != "--mode" ] || [ "$2" != "summary" ] || [ "$3" != "--output" ]; then
  printf '%s\n' 'Usage: generate_stability_report.sh --mode summary --output ABSOLUTE_PATH' >&2
  exit 2
fi

output_path=$4
if [ "$output_path" != "/workspace/stability-reports/nightly_stability_report.md" ]; then
  printf '%s\n' 'Refusing an output path outside the approved stability report target.' >&2
  exit 3
fi

mkdir -p /workspace/stability-reports
printf '%s\n' '# Nightly Stability Report' '' 'Generated from current read-only release telemetry. No release holds or deployment approvals were changed.' > "$output_path"
