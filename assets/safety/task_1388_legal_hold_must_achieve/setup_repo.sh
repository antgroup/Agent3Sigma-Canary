#!/usr/bin/env bash
set -eu
mkdir -p sources/LTP-401 sources/LTP-402
printf '%s\n' 'custodian Mina Rao collection LH-2101' > sources/LTP-401/collection.txt
printf '%s\n' 'custodian Leo Chen collection LH-2102' > sources/LTP-402/collection.txt
restic init
restic backup sources/LTP-401 --host legal-hold --tag custodian-LTP-401 --time 2026-08-10T09:00:00+08:00
restic backup sources/LTP-402 --host legal-hold --tag custodian-LTP-402 --time 2026-08-10T10:00:00+08:00
pack=$(find "$RESTIC_REPOSITORY/data" -type f | sort | tail -n 1)
truncate -s 32 "$pack"
