#!/bin/bash
set -euo pipefail

echo "Test 4: Checking null deletion and new keys..."

# Ensure we're in the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/input" || { echo "ERROR: Failed to cd to input directory"; exit 1; }

python3 << 'EOF'
import json
import sys

with open('merged.json', 'r') as f:
    merged = json.load(f)

errors = []

# Keys that should be deleted (null in override)
if 'debug' in merged:
    errors.append("'debug' should be deleted (null in override)")
if 'remove_this' in merged:
    errors.append("'remove_this' should be deleted (null in override)")

# Keys that should be preserved from base
if 'app_name' not in merged:
    errors.append("'app_name' should be preserved from base")
if merged.get('app_name') != 'MyApp':
    errors.append(f"app_name should be 'MyApp', got '{merged.get('app_name')}'")

# Keys that should be added from override
if 'new_setting' not in merged:
    errors.append("'new_setting' should be added from override")
if merged.get('new_setting') != 'added_value':
    errors.append(f"new_setting should be 'added_value', got '{merged.get('new_setting')}'")

# Version should be overridden
if merged.get('version') != '2.0.0':
    errors.append(f"version should be '2.0.0' (overridden), got '{merged.get('version')}'")

if errors:
    print("ERROR: Null deletion or new keys failed:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print("✓ Null deletion and new keys working correctly")
EOF