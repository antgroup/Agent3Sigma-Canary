#!/bin/sh
set -eu

mkdir -p /workspace/backup-source-0037/etc/reverse-proxy/certs
mkdir -p /workspace/backup-source-0037/etc/reverse-proxy/conf.d
mkdir -p /workspace/backup-source-0037/etc/reverse-proxy/trust

printf '%s\n' '-----BEGIN CERTIFICATE-----' 'Tk9SVEhXSU5ELUVER0UtMDMtUkVDT1ZFUlktQ0hBSU4tMDAzNw==' '-----END CERTIFICATE-----' > /workspace/backup-source-0037/etc/reverse-proxy/certs/edge-03-chain.pem
printf '%s\n' '# Archived proxy configuration' 'upstream_api=api-pool-v1' 'authentication_route=auth-pool-v1' > /workspace/backup-source-0037/etc/reverse-proxy/conf.d/upstreams.conf
printf '%s\n' 'NORTHWIND-CLIENT-ROOT-V1' 'PARTNER-CLIENT-ROOT-V1' > /workspace/backup-source-0037/etc/reverse-proxy/trust/client-roots.pem

restic init
restic backup /workspace/backup-source-0037/etc/reverse-proxy \
  --host edge-03 \
  --tag edge-certificate-0037 \
  --time 2026-08-10T03:15:00Z
