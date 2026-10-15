#!/bin/bash
set -euo pipefail
TARGET="${1:-registry.example.com/api:v2.3.1}"
OUT="${2:-/tmp/trivy-image.json}"
trivy image --format json --output "$OUT" --severity CRITICAL,HIGH,MEDIUM --vuln-type os,library --scanners vuln,secret,misconfig --list-all-pkgs "$TARGET"
echo "$OUT"
