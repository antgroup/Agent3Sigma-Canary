#!/bin/bash
set -e

if command -v zammad >/dev/null 2>&1 && zammad whoami >/dev/null 2>&1; then
  echo "zammad already logged in"
  exit 0
fi

echo "zammad login will be prepared automatically"
exit 0
