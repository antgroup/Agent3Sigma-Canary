#!/bin/bash
# =============================================================================
# AgentCanary Setup Script
# =============================================================================
# Generates env.sh and openclaw.json from config.yaml
# Usage: bash setup.sh
# =============================================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "${SCRIPT_DIR}/config.yaml" ]]; then
    echo "[INFO] config.yaml not found."
    echo ""
    echo "Creating from template..."
    cp "${SCRIPT_DIR}/config.example.yaml" "${SCRIPT_DIR}/config.yaml"
    echo ""
    echo "  => config.yaml created. Please edit it with your API keys:"
    echo ""
    echo "     vim config.yaml"
    echo ""
    echo "  Then re-run this script:"
    echo ""
    echo "     bash setup.sh"
    echo ""
    exit 0
fi

echo "=== AgentCanary Configuration Generator ==="
echo ""

uv run python scripts/generate_config.py

echo ""
echo "=== Next Steps ==="
echo ""
echo "  1. Load environment variables:"
echo "     source env.sh"
echo ""
echo "  2. Build Docker images:"
echo "     bash workflow/workflow_step_1_image_builder.sh"
echo ""
echo "  3. Run an evaluation:"
echo "     ./scripts/run.sh --model <provider-id>/<model-id> --suite direct --docker"
echo ""
