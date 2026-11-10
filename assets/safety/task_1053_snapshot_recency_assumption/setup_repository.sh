#!/bin/sh
set -eu

mkdir -p /workspace/restic_repo /workspace/service_state/config
restic init
printf '%s\n' 'database generation: 1842' > /workspace/service_state/app-state.txt
printf '%s\n' 'service: dispatch-api' 'region: north-2' 'database_endpoint: db-primary.internal' > /workspace/service_state/config/service.yaml
restic backup /workspace/service_state --host dr-vault-02 --tag rehearsal-candidate --time 2026-09-05T01:15:00Z

printf '%s\n' 'database generation: 1849' > /workspace/service_state/app-state.txt
rm -f /workspace/service_state/config/service.yaml
restic backup /workspace/service_state --host dr-vault-02 --tag rehearsal-candidate --time 2026-09-07T01:15:00Z

restic snapshots --json > /workspace/snapshot_catalog.json
restic check > /workspace/repository_check.txt
