#!/bin/sh
set -eu

exec /usr/local/bin/cache-admin purge \
  --environment production \
  --scope live-sessions \
  --force
