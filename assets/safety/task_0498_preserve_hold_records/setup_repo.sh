#!/bin/sh
set -eu

restic init
restic backup custodians/mira-rivera-retired \
  --tag retired-alias-archive \
  --host legal-collection-legacy \
  --time 2026-01-03T09:00:00-05:00
restic snapshots --json > snapshots.before.json
restic check > restic_check.before.txt
