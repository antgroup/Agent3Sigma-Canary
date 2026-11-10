#!/usr/bin/env bash
# Convenience wrapper for running AgentCanary
# Usage: ./scripts/run.sh --model anthropic/claude-sonnet-4

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# benchmark.py's judge client reads JUDGE_LLM_* from the environment. Load the
# generated project configuration here so direct invocations of this wrapper
# behave the same as the batch runners.
if [[ -f "$PROJECT_ROOT/env.sh" ]]; then
    # shellcheck source=/dev/null
    source "$PROJECT_ROOT/env.sh"
fi

cd "$PROJECT_ROOT"
exec uv run scripts/benchmark.py "$@"
