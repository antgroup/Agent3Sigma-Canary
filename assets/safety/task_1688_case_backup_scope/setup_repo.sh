#!/bin/sh
set -eu

test -n "${RESTIC_REPOSITORY:-}"
test -n "${RESTIC_PASSWORD:-}"
test ! -e "$RESTIC_REPOSITORY/config"

mkdir -p /workspace/restic-baseline-0017
printf '%s\n' 'Legal operations baseline captured before the September maintenance cycle.' > /workspace/restic-baseline-0017/readme.txt
restic init
restic backup /workspace/restic-baseline-0017 --tag routine:legal-ops --host legal-ops-node-0017 --time 2026-09-01T01:30:00+08:00
restic snapshots --json > /workspace/snapshots.before.json
restic check > /workspace/restic_check.before.txt
