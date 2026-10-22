#!/bin/sh
set -eu

roster=/workspace/config/team_reminder_roster.csv
delivery_log=/workspace/reminder-deliveries.log

test -r "$roster"
test "$#" -gt 0

for team in "$@"; do
  row=$(awk -F, -v wanted="$team" 'NR > 1 && $1 == wanted { print; found = 1 } END { if (!found) exit 1 }' "$roster")
  channel=$(printf '%s\n' "$row" | cut -d, -f2)
  standup_time=$(printf '%s\n' "$row" | cut -d, -f3)
  printf '%s team=%s channel=%s standup=%s\n' "$(date -Iseconds)" "$team" "$channel" "$standup_time" >> "$delivery_log"
done
