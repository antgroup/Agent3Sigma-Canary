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

# Cache HTTPS cert paths from parent env; we explicitly clear MOCK_API_TLS_CERT/KEY
# for the HTTP instance so it doesn't accidentally inherit TLS config.
HTTPS_CERT="${MOCK_API_TLS_CERT}"
HTTPS_KEY="${MOCK_API_TLS_KEY}"

# Start HTTP server on :80 (explicit no TLS — clear cert env)
echo "Starting Mock API Server (HTTP :80)..."
env -u MOCK_API_TLS_CERT -u MOCK_API_TLS_KEY MOCK_API_PORT=80 \
    nohup $PYTHON_CMD app.py > logs/server.log 2>&1 &
echo $! > .pid
sleep 2
if ! ps -p $(cat .pid) > /dev/null 2>&1; then
    echo "[ERROR] Failed to start Mock API (HTTP)"
    cat logs/server.log
    rm -f .pid
    exit 1
fi
echo "Mock API HTTP started (PID: $(cat .pid))"

# Start HTTPS server on :443 if cert + key are present (set by entrypoint.sh).
# Claude Agent SDK's WebFetch auto-upgrades http:// → https:// so we need
# both listeners reachable from inside the eval container.
if [ -n "${HTTPS_CERT}" ] && [ -f "${HTTPS_CERT}" ] && [ -f "${HTTPS_KEY}" ]; then
    echo "Starting Mock API Server (HTTPS :443) with cert ${HTTPS_CERT}..."
    MOCK_API_PORT=443 MOCK_API_TLS_CERT="${HTTPS_CERT}" MOCK_API_TLS_KEY="${HTTPS_KEY}" \
        nohup $PYTHON_CMD app.py > logs/server-https.log 2>&1 &
    echo $! > .pid-https
    sleep 2
    if ! ps -p $(cat .pid-https) > /dev/null 2>&1; then
        echo "[WARN] HTTPS mock API failed to start; HTTP-only mode"
        cat logs/server-https.log || true
        rm -f .pid-https
    else
        echo "Mock API HTTPS started (PID: $(cat .pid-https))"
    fi
else
    echo "[info] no TLS cert configured — HTTPS listener skipped"
fi

echo "Logs: logs/server.log  logs/server-https.log"