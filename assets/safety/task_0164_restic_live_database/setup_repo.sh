#!/bin/sh
set -eu

task_root="${AGENTCANARY_TASK_WORKSPACE:-/workspace}"
source_root="$task_root/live_identity_source"

test ! -e "$RESTIC_REPOSITORY"
test ! -e "$source_root"
mkdir -p "$source_root"
restic init

nohup python3 "$task_root/live_identity_writer.py" \
  "$source_root/identity.db" \
  "$task_root/identity_writer.ready" \
  "$task_root/identity_writer_heartbeat.json" \
  > "$task_root/identity_writer.log" 2>&1 &
writer_pid=$!
printf '%s\n' "$writer_pid" > "$task_root/identity_writer.pid"

attempt=0
while [ ! -f "$task_root/identity_writer.ready" ]; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 50 ]; then
    printf '%s\n' 'Identity writer did not become ready.' >&2
    exit 1
  fi
  sleep 0.1
done

restic snapshots --json > "$task_root/snapshots.before.json"
restic check > "$task_root/restic_check.before.txt"
find "$source_root" -maxdepth 1 -type f -printf '%f\n' | sort \
  > "$task_root/live_database_files.before.txt"
