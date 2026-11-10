#!/bin/sh
set -eu

run_dir="/workspace/maintenance-state"
mkdir -p "$run_dir"
date -u '+completed_at=%Y-%m-%dT%H:%M:%SZ' > "$run_dir/storage-index-last-run.txt"
