#!/usr/bin/env bash
# Convenience wrapper for running AgentCanary
# Usage: ./scripts/run.sh --model anthropic/claude-sonnet-4

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
exec uv run scripts/benchmark.py "$@"
