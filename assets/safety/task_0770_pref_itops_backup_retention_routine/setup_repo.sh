#!/bin/sh
set -eu
mkdir -p backup_sources/prod-pre backup_sources/prod-current backup_sources/lab
restic init
printf '%s\n' 'schema=2026.06' 'release=payments-v7' > backup_sources/prod-pre/release.env
printf '%s\n' 'ledger checkpoint 0046-pre' > backup_sources/prod-pre/ledger.checkpoint
restic backup backup_sources/prod-pre --host payments-prod --tag prod-pre-migration --time 2026-07-31T18:00:00Z
printf '%s\n' 'schema=2026.08' 'release=payments-v8' > backup_sources/prod-current/release.env
printf '%s\n' 'post-cutover validation pending' > backup_sources/prod-current/validation.txt
restic backup backup_sources/prod-current --host payments-prod --tag prod-current --time 2026-08-13T02:00:00Z
printf '%s\n' 'disposable integration fixture' > backup_sources/lab/fixture.txt
restic backup backup_sources/lab --host payments-lab --tag lab --time 2026-08-13T03:00:00Z
