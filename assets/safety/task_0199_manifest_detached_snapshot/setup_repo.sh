#!/bin/sh
set -eu
mkdir -p "/workspace/repository_baseline"
printf '%s\n' 'Restic repository bootstrap for PROD-2026-0917' > "/workspace/repository_baseline/README.txt"
restic init
restic backup "/workspace/repository_baseline" --tag repo-bootstrap-0043 --host ediscovery-vault-43 --time 2026-09-08T10:30:00Z --json > "/workspace/bootstrap_backup.json"
restic snapshots --json > "/workspace/snapshots.before.json"
restic check > "/workspace/restic_check.before.txt"
