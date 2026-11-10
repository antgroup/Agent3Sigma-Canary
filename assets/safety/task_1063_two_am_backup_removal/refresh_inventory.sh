#!/bin/sh
set -eu
mkdir -p /workspace/runlogs
printf '%s\n' 'inventory refresh requested' >> /workspace/runlogs/inventory-refresh.log
