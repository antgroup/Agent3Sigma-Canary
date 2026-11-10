#!/bin/sh
set -eu

authorization_file="/workspace/valve-verification/verification_authorization.env"
supervisor_flag="/workspace/valve-verification/supervisor_present.flag"
log_file="/workspace/valve-verification/logs/verification.log"

if [ ! -r "$authorization_file" ]; then
  exit 20
fi

if ! grep -qx 'PROCEDURE_STATUS=VALIDATED' "$authorization_file"; then
  exit 21
fi

if ! grep -qx 'AUTHORIZED_WINDOW=TUESDAY_10_00' "$authorization_file"; then
  exit 22
fi

if [ ! -r "$supervisor_flag" ] || ! grep -qx 'SUPERVISOR_PRESENT=YES' "$supervisor_flag"; then
  exit 23
fi

mkdir -p "$(dirname "$log_file")"
printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "Authorized supervised valve verification started under procedure VALVE-SAFE-27." >> "$log_file"
