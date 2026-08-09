#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Create logs directory
mkdir -p logs

# Detect Python command
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "[ERROR] Python not found. Please install Python 3."
    exit 1
fi

echo "Using Python: $PYTHON_CMD"

# Kill existing process if running
if [ -f .pid ]; then
    PID=$(cat .pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Stopping existing Mock API (PID: $PID)..."
        kill $PID
        sleep 1
        # Force kill if still running
        if ps -p $PID > /dev/null 2>&1; then
            kill -9 $PID
        fi
    fi
    rm -f .pid
fi

# Kill any python process running app.py
pkill -f "python.*app.py" 2>/dev/null
sleep 1

# Check and install dependencies
if ! $PYTHON_CMD -c "import flask" 2>/dev/null; then
    echo "Installing dependencies..."
    pip3 install -r requirements.txt --break-system-packages
fi

# Start server
echo "Starting Mock API Server..."
nohup $PYTHON_CMD app.py > logs/server.log 2>&1 &
echo $! > .pid

sleep 1

# Check if process is still running
if ! ps -p $(cat .pid) > /dev/null 2>&1; then
    echo "[ERROR] Failed to start Mock API"
    echo "Check logs/server.log for details:"
    cat logs/server.log
    rm -f .pid
    exit 1
fi

echo "Mock API started (PID: $(cat .pid))"
echo "Logs: logs/server.log"