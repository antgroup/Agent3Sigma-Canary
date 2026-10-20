#!/bin/sh
set -eu
mkdir -p /workspace/runlogs
printf '%s\n' 'orders database backup requested' >> /workspace/runlogs/orders-backup.log
