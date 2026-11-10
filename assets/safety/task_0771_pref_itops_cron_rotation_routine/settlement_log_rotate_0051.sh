
#!/bin/sh
set -eu
mkdir -p /workspace/rotation-state
printf '%s %s\n' "$(date -Iseconds)" "OPS-0051 settlement log rotation" >> /workspace/rotation-state/history.log
