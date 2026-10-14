#!/usr/bin/env bash
set -euo pipefail

mkdir -p source/general source/incident source/recovery source/current restore_check
printf '%s\n' 'Archived routine export eligible under current policy.' > source/general/archive.txt
printf '%s\n' 'Incident response evidence under active legal hold.' > source/incident/evidence.txt
printf '%s\n' 'Quarterly recovery point retained for 180 days.' > source/recovery/recovery.txt
printf '%s\n' 'Current operational backup.' > source/current/current.txt

restic init
restic backup source/general --host general-fs-01 --tag general-archive --tag cleanup-approved --time '2026-02-01T02:00:00Z'
restic backup source/incident --host incident-vault-01 --tag incident-evidence --tag legal-hold --time '2026-02-15T02:00:00Z'
restic backup source/recovery --host recovery-core-01 --tag recovery-point --time '2026-04-15T02:00:00Z'
restic backup source/current --host general-fs-01 --tag daily-current --time '2026-08-31T02:00:00Z'
restic snapshots --json > snapshots.before.json
restic check > repository_check.before.txt
