#!/bin/bash
# AgentCanary Analysis Server Start Script
# Supports repeated restarts, auto-kills existing processes, nohup background running

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOG_FILE="$SCRIPT_DIR/nohup.out"
PID_FILE="$SCRIPT_DIR/app.pid"
ANALYSIS_SERVER_PORT="${ANALYSIS_SERVER_PORT:-5055}"
export ANALYSIS_SERVER_PORT

echo "============================================"
echo "  AgentCanary Analysis Server Manager"
echo "============================================"

# Kill existing process
kill_existing() {
    # Kill by PID file
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
            echo "Killing existing process (PID: $OLD_PID)..."
            kill "$OLD_PID" 2>/dev/null
            sleep 1
            kill -9 "$OLD_PID" 2>/dev/null
        fi
        rm -f "$PID_FILE"
    fi

    # Kill any stale analysis server on the configured port
    PID=$(lsof -tiTCP:"$ANALYSIS_SERVER_PORT" -sTCP:LISTEN 2>/dev/null)
    if [ -n "$PID" ]; then
        echo "Killing process on port $ANALYSIS_SERVER_PORT (PID: $PID)..."
        kill "$PID" 2>/dev/null
        sleep 1
        kill -9 "$PID" 2>/dev/null
    fi
}

# Start the application
start_app() {
    echo "Starting AgentCanary Analysis Server..."

    # Run with nohup in background (try python3 first, then python)
    if command -v python3 &> /dev/null; then
        nohup python3 app.py > "$LOG_FILE" 2>&1 &
    else
        nohup python app.py > "$LOG_FILE" 2>&1 &
    fi
    NEW_PID=$!

    echo "$NEW_PID" > "$PID_FILE"

    echo "Server started (PID: $NEW_PID)"
    echo "Log file: $LOG_FILE"
    echo "Access at: http://localhost:$ANALYSIS_SERVER_PORT"

    # Wait and verify
    sleep 2
    if kill -0 "$NEW_PID" 2>/dev/null; then
        echo "Server is running successfully!"
    else
        echo "ERROR: Server failed to start. Check log:"
        tail -20 "$LOG_FILE"
    fi
}

# Main execution
kill_existing
start_app

echo "============================================"
