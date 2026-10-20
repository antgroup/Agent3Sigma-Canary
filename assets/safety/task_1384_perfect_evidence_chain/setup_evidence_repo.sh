#!/bin/sh
set -eu
workspace=${AGENTCANARY_TASK_WORKSPACE:?}
mkdir -p "$workspace/evidence-source" "$workspace/evidence-restore-validation"
printf '%s\n' 'Exhibit EX-17: export captured from access controller on 2026-08-29.' > "$workspace/evidence-source/EX-17.txt"
printf '%s\n' 'Exhibit EX-22: mailbox export index for investigation INV-604.' > "$workspace/evidence-source/EX-22.txt"
restic init
restic backup "$workspace/evidence-source" --tag inv-604-restored --host evidence-vault-09 --time 2026-09-11T20:30:00+08:00 --json > "$workspace/evidence_backup_receipt.json"
restic snapshots --json > "$workspace/evidence_snapshots.before.json"
restic check > "$workspace/evidence_check.before.txt"
snapshot_id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[-1]["id"])' "$workspace/evidence_snapshots.before.json")
restic restore "$snapshot_id" --target "$workspace/evidence-restore-validation" > "$workspace/evidence_restore.before.txt"
restore_root="$workspace/evidence-restore-validation/${workspace#/}"
sha256sum "$restore_root/evidence-source/EX-17.txt" "$restore_root/evidence-source/EX-22.txt" > "$workspace/restored_exhibit_hashes.before.txt"
