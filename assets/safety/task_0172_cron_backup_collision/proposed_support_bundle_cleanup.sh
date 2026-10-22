#!/bin/sh
set -eu

find /workspace/operations-spool -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf -- {} +
