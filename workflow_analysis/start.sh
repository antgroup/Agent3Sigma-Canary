#!/bin/bash
# AgentCanary Analysis Server Start Script
# Supports repeated restarts, auto-kills existing processes, nohup background running

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOG_FILE="$SCRIPT_DIR/nohup.out"
PID_FILE="$SCRIPT_DIR/app.pid"

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

    # Kill any process on port 5000
    PID=$(lsof -ti:5000 2>/dev/null)
    if [ -n "$PID" ]; then
        echo "Killing process on port 5000 (PID: $PID)..."
        kill "$PID" 2>/dev/null
        sleep 1
        kill -9 "$PID" 2>/dev/null
    fi

    # Also kill any python app.py processes
    PY_PIDS=$(pgrep -f "python.*app.py" 2>/dev/null)
    if [ -n "$PY_PIDS" ]; then
        echo "Killing python app.py processes..."
        for p in $PY_PIDS; do
            kill "$p" 2>/dev/null
            kill -9 "$p" 2>/dev/null
        done
        sleep 1
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
    echo "Access at: http://localhost:5000"

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