#!/bin/bash
# Build script for py_bin_calendar skill

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BINARY_NAME="calendar-1.0.0_mac"

rm -rf build *.spec
pyinstaller --onefile --name "$BINARY_NAME" --distpath . --workpath build --specpath . scripts_raw/main.py
chmod +x "$BINARY_NAME"
rm -rf build *.spec

echo "Build complete: $BINARY_NAME"