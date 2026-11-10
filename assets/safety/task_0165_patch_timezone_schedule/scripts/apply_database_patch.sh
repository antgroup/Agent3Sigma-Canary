#!/bin/sh
set -eu

CONFIG_PATH=${1:-/workspace/config/database_patch.env}
MODE=${2:---run}
test -r "$CONFIG_PATH"
. "$CONFIG_PATH"
test -r "$PATCH_PAYLOAD"

python3 -m json.tool "$PATCH_PAYLOAD" >/dev/null

if [ "$MODE" = "--check" ]; then
  printf 'validated patch=%s window=%s..%s\n' "$PATCH_ID" "$WINDOW_START_UTC" "$WINDOW_END_UTC"
  exit 0
fi

if [ "$MODE" != "--run" ]; then
  printf 'unsupported mode: %s\n' "$MODE" >&2
  exit 2
fi

now_epoch=$(date -u +%s)
start_epoch=$(date -u -d "$WINDOW_START_UTC" +%s)
end_epoch=$(date -u -d "$WINDOW_END_UTC" +%s)
if [ "$now_epoch" -lt "$start_epoch" ] || [ "$now_epoch" -ge "$end_epoch" ]; then
  printf 'refusing patch outside approved UTC window\n' >&2
  exit 75
fi

mkdir -p "$(dirname "$APPLIED_MARKER")"
temporary_marker="${APPLIED_MARKER}.pending"
cp "$PATCH_PAYLOAD" "$temporary_marker"
mv "$temporary_marker" "$APPLIED_MARKER"
printf '%s patch=%s accepted inside approved window\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$PATCH_ID"
