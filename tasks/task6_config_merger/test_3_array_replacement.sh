#!/bin/bash
set -euo pipefail

echo "Test 3: Checking array replacement..."

# Ensure we're in the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/input" || { echo "ERROR: Failed to cd to input directory"; exit 1; }

python3 << 'EOF'
import json
import sys

with open('merged.json', 'r') as f:
    merged = json.load(f)

features = merged.get('features', [])
expected = ["auth", "api", "admin"]

if features != expected:
    print(f"ERROR: Features should be {expected} (replaced), got {features}")
    print("Arrays should be REPLACED, not concatenated")
    sys.exit(1)

if len(features) != 3:
    print(f"ERROR: Should have exactly 3 features, got {len(features)}")
    sys.exit(1)

print("✓ Arrays properly replaced (not concatenated)")
EOF