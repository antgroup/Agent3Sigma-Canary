#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Load config to get port
PORT=$(grep -o '"port": [0-9]*' config.json | grep -o '[0-9]*')
HOST="localhost"

echo "=========================================="
echo "Mock API Test Script"
echo "=========================================="
echo "Target: http://${HOST}:${PORT}"
echo ""

# Check if server is running
if [ -f .pid ]; then
    PID=$(cat .pid)
    if ! ps -p $PID > /dev/null 2>&1; then
        echo "[ERROR] Mock API is not running (PID: $PID is dead)"
        exit 1
    fi
else
    echo "[ERROR] Mock API is not running (no .pid file found)"
    exit 1
fi

PASS=0
FAIL=0

test_endpoint() {
    local method=$1
    local path=$2
    local expected_status=$3
    local desc=$4
    local check_content_type=$5

    echo "Testing: $desc"
    echo "  Request: $method $path"

    # Use unique separator to reliably parse response
    RESPONSE=$(curl -s -w "\nSTATUSMARK:%{http_code}\nCONTENTTYPEMARK:%{content_type}" "http://${HOST}:${PORT}${path}")

    # Extract status code and content type using unique markers
    STATUS=$(echo "$RESPONSE" | grep 'STATUSMARK:' | sed 's/STATUSMARK://')
    CONTENT_TYPE=$(echo "$RESPONSE" | grep 'CONTENTTYPEMARK:' | sed 's/CONTENTTYPEMARK://')
    BODY=$(echo "$RESPONSE" | sed '/STATUSMARK:/,$d')

    if [ "$STATUS" = "$expected_status" ]; then
        echo "  Status: $STATUS (expected: $expected_status) [PASS]"
        echo "  Content-Type: $CONTENT_TYPE"
        if [ -n "$check_content_type" ]; then
            if echo "$CONTENT_TYPE" | grep -q "$check_content_type"; then
                echo "  Content-Type check: [PASS]"
            else
                echo "  Content-Type check: [FAIL] (expected: $check_content_type)"
                ((FAIL++))
                return
            fi
        fi
        echo "  Response: $BODY"
        ((PASS++))
    else
        echo "  Status: $STATUS (expected: $expected_status) [FAIL]"
        echo "  Response: $BODY"
        ((FAIL++))
    fi
    echo ""
}

# Test endpoints
test_endpoint "GET" "/" "200" "Root endpoint"
test_endpoint "GET" "/__list" "200" "List files"
test_endpoint "GET" "/content/example" "200" "Get HTML file (no extension)" "text/html"
test_endpoint "GET" "/content/example.json" "200" "Get JSON file (with extension)" "application/json"
test_endpoint "GET" "/content/notexist" "404" "Non-existent file"
test_endpoint "POST" "/__reload" "200" "Reload config"

echo "=========================================="
echo "Test Results: $PASS passed, $FAIL failed"
echo "=========================================="

if [ $FAIL -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed!"
    exit 1
fi