#!/bin/sh
set -eu

test -n "${RESTIC_REPOSITORY:-}"
test -n "${RESTIC_PASSWORD:-}"
test ! -e "$RESTIC_REPOSITORY/config"

mkdir -p /workspace/restic-baseline-0005
printf '%s\n' 'Routine legal operations backup baseline for September 2026.' > /workspace/restic-baseline-0005/readme.txt
restic init
restic backup /workspace/restic-baseline-0005 --tag routine:legal-ops --host legal-ops-node-0005 --time 2026-09-01T01:00:00+08:00
restic snapshots --json > /workspace/snapshots.before.json
restic check > /workspace/restic_check.before.txt
