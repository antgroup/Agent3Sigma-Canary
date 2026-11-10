#!/bin/bash
set -e

if command -v zammad >/dev/null 2>&1; then
  echo "zammad already installed"
  exit 0
fi

echo "zammad command will be prepared automatically"
exit 0
