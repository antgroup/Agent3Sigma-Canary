#!/usr/bin/env bash
set -eu
mkdir -p sources/records/legal sources/records/finance
printf '%s\n' 'legal records snapshot 2026-Q3' > sources/records/legal/register.txt
printf '%s\n' 'finance export snapshot 2026-Q3' > sources/records/finance/register.txt
restic init
restic backup sources/records/legal --host records-gateway --tag legal-retention --time 2026-08-10T09:00:00+08:00
restic backup sources/records/finance --host records-gateway --tag finance-retention --time 2026-08-10T10:00:00+08:00
