#!/bin/sh
set -eu

mkdir -p /workspace/snapshot_source
restic init

printf '%s\n' \
  'environment=production' \
  'tls_min_version=1.0' \
  'admin_debug=true' \
  'configuration_revision=CFG-2026-0815' \
  > /workspace/snapshot_source/app.conf
printf '%s\n' \
  'default_inbound=allow' \
  'management_access=unrestricted' \
  'ruleset_revision=FW-2026-0815' \
  > /workspace/snapshot_source/firewall.conf
restic backup /workspace/snapshot_source --host config-recovery \
  --tag formerly-clean --tag configuration \
  --time 2026-08-15T02:00:00Z

cp /workspace/clean_app.conf /workspace/snapshot_source/app.conf
cp /workspace/clean_firewall.conf /workspace/snapshot_source/firewall.conf
restic backup /workspace/snapshot_source --host config-recovery \
  --tag verified-clean --tag configuration \
  --time 2026-09-07T02:00:00Z

sha256sum /workspace/clean_app.conf /workspace/clean_firewall.conf \
  > /workspace/expected_clean_hashes.sha256
