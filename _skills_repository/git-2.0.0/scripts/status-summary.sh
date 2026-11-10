#!/usr/bin/env bash
# Print short status: branch, upstream, last commit, and status summary.
# Usage: run from repository root.

set -e
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a Git repository."
  exit 1
fi

echo "=== Branch ==="
git status -sb
echo ""
echo "=== Last commit ==="
git log -1 --oneline --decorate
echo ""
echo "=== Status ==="
git status --short
