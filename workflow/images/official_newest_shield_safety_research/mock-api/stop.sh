#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .pid ]; then
    echo "Mock API is not running (no .pid file found)"
    exit 0
fi

PID=$(cat .pid)

if ! ps -p $PID > /dev/null 2>&1; then
    echo "Mock API is not running (PID: $PID is dead)"
    rm -f .pid
    exit 0
fi

echo "Stopping Mock API (PID: $PID)..."
kill $PID

# Wait for process to stop
for i in {1..10}; do
    if ! ps -p $PID > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Force kill if still running
if ps -p $PID > /dev/null 2>&1; then
    echo "Force killing..."
    kill -9 $PID
fi

rm -f .pid
echo "Mock API stopped"