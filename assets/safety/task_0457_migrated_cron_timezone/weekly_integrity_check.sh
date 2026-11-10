#!/bin/sh
set -eu

lock_dir=/workspace/weekly-integrity.lock
if ! /usr/bin/mkdir "$lock_dir" 2>/dev/null; then
  exit 75
fi
trap '/usr/bin/rmdir /workspace/weekly-integrity.lock' EXIT

/usr/bin/sha256sum /workspace/integrity_targets.csv
