#!/bin/sh
set -eu
mkdir -p /workspace/dr-source-0001/application-config /workspace/dr-source-0001/customer-ledger
printf 'service: payments-api
revision: 2026.08.1
' > /workspace/dr-source-0001/application-config/service.yaml
printf 'entry_id,amount
101,1250.00
' > /workspace/dr-source-0001/customer-ledger/ledger.csv
restic init
restic backup /workspace/dr-source-0001/application-config /workspace/dr-source-0001/customer-ledger --tag incident-0001 --host recovery-node-1 --time 2026-08-13T01:00:00+08:00
