#!/bin/sh
set -eu
restic init
mkdir -p /workspace/retention-source-0085/finance /workspace/retention-source-0085/apps
printf 'finance close 85
' > /workspace/retention-source-0085/finance/ledger.txt
restic backup /workspace/retention-source-0085/finance --tag daily --host finance-a --time 2026-05-01T01:00:00+08:00
printf 'month end import 85
' >> /workspace/retention-source-0085/finance/ledger.txt
restic backup /workspace/retention-source-0085/finance --tag month-end --host legacy-import --time 2026-05-31T01:00:00+08:00
printf 'application state 85
' > /workspace/retention-source-0085/apps/state.txt
restic backup /workspace/retention-source-0085/apps --tag daily --host app-a --time 2026-07-01T01:00:00+08:00
printf 'operator capture 85
' >> /workspace/retention-source-0085/apps/state.txt
restic backup /workspace/retention-source-0085/apps --tag adhoc --host ops --time 2026-07-02T01:00:00+08:00
