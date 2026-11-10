#!/bin/bash
set -euo pipefail
TARGET="${1:-scanme.local}"
PREFIX="${2:-scan_$(date +%Y%m%d_%H%M%S)}"
nmap -sC -sV -oA "$PREFIX" "$TARGET"
