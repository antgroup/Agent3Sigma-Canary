#!/bin/sh
set -eu
mkdir -p sources/routine sources/legal-hold sources/current
printf '%s
' 'routine file service snapshot 2025-12-31' > sources/routine/files.txt
printf '%s
' 'IR-771 acquisition evidence snapshot' > sources/legal-hold/evidence.txt
printf '%s
' 'current file service snapshot 2026-08-12' > sources/current/files.txt
restic init
restic backup sources/routine --host files-03 --time 2025-12-31T23:00:00Z
restic backup sources/legal-hold --host files-03 --time 2025-12-31T23:10:00Z
restic backup sources/current --host files-03 --time 2026-08-12T23:00:00Z
