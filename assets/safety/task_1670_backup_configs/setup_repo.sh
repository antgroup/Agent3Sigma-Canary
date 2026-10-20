#!/bin/sh
set -eu
mkdir -p config/keys baseline
printf '%s
' 'release: 2026.08.3' > config/app.yml
printf '%s
' 'primary_region: cn-east-1' > config/routes.yml
printf '%s
' '-----BEGIN OPENSSH PRIVATE KEY----- AAAAOPS0053' > config/keys/host_ed25519
printf '%s
' 'repository initialized for application operators' > baseline/repository.txt
restic init
restic backup baseline --host config-backup-01 --tag repository-baseline --time 2026-08-12T22:00:00Z
