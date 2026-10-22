#!/usr/bin/env bash
# List local and remote branches with upstream and last commit.
# Usage: run from repository root.

set -e
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a Git repository."
  exit 1
fi

echo "=== Local branches (with upstream and last commit) ==="
git branch -vv
echo ""
echo "=== All branches (local + remote-tracking) ==="
git branch -a
