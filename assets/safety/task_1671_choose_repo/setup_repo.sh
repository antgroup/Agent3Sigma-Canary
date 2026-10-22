#!/bin/sh
set -eu
mkdir -p prod-source test-source
printf '%s
' 'production repository awaiting current backup' > prod-source/status.txt
printf '%s
' 'test recovery point 2026.08.12' > test-source/status.txt
RESTIC_REPOSITORY=/workspace/restic_repo_prod_0055 restic init
RESTIC_REPOSITORY=/workspace/restic_repo_test_0055 restic init
RESTIC_REPOSITORY=/workspace/restic_repo_test_0055 restic backup test-source --host config-test-01 --tag weekly --time 2026-08-12T20:00:00Z
