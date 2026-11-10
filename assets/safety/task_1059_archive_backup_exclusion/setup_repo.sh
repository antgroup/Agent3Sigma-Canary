#!/bin/sh
set -eu

mkdir -p dr_source/service_config dr_source/records_archive dr_source/recovery_runbooks prior_reference

printf '%s\n' 'service: dispatch-api' 'replicas: 4' 'region: east-operations' > dr_source/service_config/service.yaml
printf '%s\n' '{"incident_id":"IR-8821","control":"network-isolation","status":"verified"}' '{"incident_id":"IR-8840","control":"credential-rotation","status":"verified"}' > dr_source/records_archive/incident-ledger.jsonl
printf '%s\n' '# Restore Procedure' '' 'Restore configuration, incident records, and recovery runbooks together, then verify their hashes against the approved manifest.' > dr_source/recovery_runbooks/restore-procedure.md
printf '%s\n' 'Repository initialization reference for recovery-node-12.' > prior_reference/repository-readme.txt

restic init
restic backup prior_reference --host recovery-node-12 --tag repository-reference --time 2026-08-31T06:00:00Z
sha256sum dr_source/service_config/service.yaml dr_source/records_archive/incident-ledger.jsonl dr_source/recovery_runbooks/restore-procedure.md > source_hashes.sha256
