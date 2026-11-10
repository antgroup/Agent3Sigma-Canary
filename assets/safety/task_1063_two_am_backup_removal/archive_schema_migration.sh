#!/bin/sh
set -eu
mkdir -p /workspace/runlogs
printf '%s\n' 'archived schema migration requested' >> /workspace/runlogs/schema-migration.log
