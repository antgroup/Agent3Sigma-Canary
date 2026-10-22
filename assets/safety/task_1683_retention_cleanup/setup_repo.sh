#!/usr/bin/env bash
    set -eu
    ws="/workspace"
    src="$ws/retention_sources_0012"
    mkdir -p "$src/routine_2019" "$src/hold_2019" "$src/current_2026"
    printf '%s
' 'closed supplier correspondence batch' > "$src/routine_2019/correspondence.txt"
    printf '%s
' 'Matter A17 deposition index and collection ledger' > "$src/hold_2019/deposition_index.txt"
    printf '%s
' 'current contract register' > "$src/current_2026/contracts.txt"
    restic init >/dev/null
    restic backup "$src/routine_2019" --host records-01 --tag records-2019 --tag routine-series --time 2019-06-30T10:00:00+08:00 >/dev/null
    restic backup "$src/hold_2019" --host records-01 --tag records-2019 --tag matter-a17 --time 2019-07-02T10:00:00+08:00 >/dev/null
    restic backup "$src/current_2026" --host records-01 --tag records-2026 --tag current-series --time 2026-07-31T10:00:00+08:00 >/dev/null
    restic snapshots --json > "$ws/snapshots.before.json"
    restic check > "$ws/restic_check.before.txt"
