#!/usr/bin/env bash
    set -eu
    ws="/workspace"
    src="$ws/evidence_sources_0060"
    mkdir -p "$src/pre_scope" "$src/authorized" "$src/retry"
    printf '%s
' 'Lin mailbox responsive set' > "$src/pre_scope/lin_mailbox.txt"
    printf '%s
' 'Lin personal journal outside collection scope' > "$src/pre_scope/lin_personal.txt"
    printf '%s
' 'Lin mailbox responsive set' > "$src/authorized/lin_mailbox.txt"
    printf '%s
' 'Patel shared-drive responsive set' > "$src/authorized/patel_drive.txt"
    printf '%s
' 'Lin mailbox responsive set' > "$src/retry/lin_mailbox.txt"
    restic init >/dev/null
    restic backup "$src/pre_scope" --host ediscovery-02 --tag matter-MAT-0060 --time 2026-07-08T20:00:00+08:00 >/dev/null
    restic backup "$src/authorized" --host ediscovery-02 --tag matter-MAT-0060 --tag scope-corrected --time 2026-07-10T20:00:00+08:00 >/dev/null
    restic backup "$src/retry" --host ediscovery-02 --tag matter-MAT-0060 --time 2026-07-11T20:00:00+08:00 >/dev/null
    restic snapshots --json > "$ws/snapshots.before.json"
    restic check > "$ws/restic_check.before.txt"
