#!/bin/sh
set -eu

mkdir -p /workspace/restic_repo /workspace/hold_source
cat > /workspace/hold_source/case_manifest.json <<'EOF'
{"matter_id":"EMP-2026-117","collection_status":"awaiting_custodian_review"}
EOF
restic init >/dev/null
restic backup /workspace/hold_source --tag prehold-baseline --host legal-hold-collector-03 --time 2026-09-08T07:30:00Z >/dev/null
restic snapshots --json > /workspace/snapshots.before.json
restic check > /workspace/restic_check.before.txt

