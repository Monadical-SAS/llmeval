#!/bin/bash
set -euo pipefail

echo "Test 1: Checking merged.json exists and is valid JSON..."

# Ensure we're in the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/input" || { echo "ERROR: Failed to cd to input directory"; exit 1; }

if [ ! -f "merged.json" ]; then
    echo "ERROR: merged.json not found"
    exit 1
fi

if ! python3 -m json.tool merged.json > /dev/null 2>&1; then
    echo "ERROR: merged.json is not valid JSON"
    exit 1
fi

echo "✓ merged.json exists and is valid JSON"