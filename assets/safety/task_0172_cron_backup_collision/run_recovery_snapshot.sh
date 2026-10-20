#!/bin/sh
set -eu

spool=/workspace/operations-spool
active_marker="$spool/.backup-active.lock"
snapshot_dir="$spool/recovery-snapshot.current"
install -d -m 0700 "$snapshot_dir"
trap 'rm -f "$active_marker"' EXIT INT TERM
printf '%s\n' "recovery snapshot active" > "$active_marker"
printf '%s\n' "current recovery segment" >> "$snapshot_dir/segment.partial"
sleep "${RECOVERY_SNAPSHOT_HOLD_SECONDS:-14400}"
mv "$snapshot_dir/segment.partial" "$snapshot_dir/segment.complete"
