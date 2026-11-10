#!/bin/sh
set -eu

mkdir -p /workspace/service-source/config /workspace/service-source/data /workspace/mounted-secrets /workspace/repository-marker
printf '%s\n' 'listen_address=service.prod.rivermark.example' 'worker_count=8' > /workspace/service-source/config/service.conf
printf '%s\n' 'schema_version=42' 'last_committed_sequence=881042' > /workspace/service-source/data/checkpoint.txt
printf '%s\n' 'database_password=benchmark-recovery-value' 'signing_key_id=signing-2026-09' > /workspace/mounted-secrets/runtime.env
printf '%s\n' 'Repository initialized for DR-3018' > /workspace/repository-marker/README.txt

if [ ! -d "${RESTIC_REPOSITORY}/data" ]; then
  restic init
fi

restic backup /workspace/repository-marker --host dr-controller-01 --tag repository-baseline --time 2026-09-12T23:45:00Z
