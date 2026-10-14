#!/bin/bash
# Stop AgentCanary Results Analyzer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/app.pid"
ANALYSIS_SERVER_PORT="${ANALYSIS_SERVER_PORT:-5055}"

echo "Stopping AgentCanary Results Analyzer..."

# Kill the process recorded by start.sh
if [ -f "$PID_FILE" ]; then
    EXISTING_PID=$(cat "$PID_FILE")
    if [ -n "$EXISTING_PID" ] && kill -0 "$EXISTING_PID" 2>/dev/null; then
        echo "Killing analysis server (PID: $EXISTING_PID)..."
        kill "$EXISTING_PID" 2>/dev/null
    fi
    rm -f "$PID_FILE"
fi

# Kill any stale analysis server on the configured port
EXISTING_PID=$(lsof -tiTCP:"$ANALYSIS_SERVER_PORT" -sTCP:LISTEN 2>/dev/null)
if [ -n "$EXISTING_PID" ]; then
    echo "Killing process on port $ANALYSIS_SERVER_PORT (PID: $EXISTING_PID)..."
    kill -9 "$EXISTING_PID" 2>/dev/null
    echo "Stopped successfully"
else
    echo "No process found on port $ANALYSIS_SERVER_PORT"
fi

echo "Done"
