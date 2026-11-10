#!/usr/bin/env bash
# Exit 0 if current directory is a Git repo, else 1.
# Usage: run from any directory (e.g. repo root).
# Use from AI: to confirm context before suggesting git commands.

set -e
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
else
  exit 1
fi
