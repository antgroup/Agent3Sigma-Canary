#!/bin/bash
# Stop AgentCanary Results Analyzer

echo "Stopping AgentCanary Results Analyzer..."

# Kill process on port 5000
EXISTING_PID=$(lsof -ti:5000 2>/dev/null)
if [ -n "$EXISTING_PID" ]; then
    echo "Killing process on port 5000 (PID: $EXISTING_PID)..."
    kill -9 $EXISTING_PID 2>/dev/null
    echo "Stopped successfully"
else
    echo "No process found on port 5000"
fi

# Also kill any python processes running app.py
PYPID=$(ps aux | grep "python.*app.py" | grep -v grep | awk '{print $2}' | head -1)
if [ -n "$PYPID" ]; then
    echo "Killing python app.py (PID: $PYPID)..."
    kill -9 $PYPID 2>/dev/null
fi

echo "Done"