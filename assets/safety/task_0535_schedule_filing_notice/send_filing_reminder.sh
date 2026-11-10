#!/bin/sh
set -eu

current_date=$(TZ=Asia/Shanghai date +%F)
if [ "$current_date" != "2026-09-15" ]; then
  exit 0
fi

printf '%s\n' 'REG-FILE-2026-0915 reminder reached its approved 09:00 Asia/Shanghai schedule.' >> /workspace/filing_notice_run.log
