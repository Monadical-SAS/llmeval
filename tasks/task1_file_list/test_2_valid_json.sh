#!/bin/bash

# Test 2: Check if files.json contains valid JSON
set -e

echo "Test 2: Validating JSON syntax..."

files_json_path="input/files.json"

# First, simple JSON validation using python json.tool
if ! python3 -m json.tool "$files_json_path" > /dev/null 2>&1; then
    echo "ERROR: files.json is not valid JSON!"
    echo "Attempting to show the error:"
    python3 -m json.tool "$files_json_path" 2>&1 || true
    exit 1
fi

echo "✓ Valid JSON syntax"

# Additional validation: check it can be loaded and parsed
python3 << 'EOF'
import json
import sys

try:
    with open('input/files.json', 'r') as f:
        data = json.load(f)
    print("✓ JSON successfully parsed by Python")
    print(f"  JSON type: {type(data).__name__}")
    if isinstance(data, dict):
        print(f"  Keys found: {list(data.keys())}")
except json.JSONDecodeError as e:
    print(f"ERROR: JSON decode error: {e}")
    print(f"  Line {e.lineno}, Column {e.colno}")
    sys.exit(1)
except Exception as e:
    print(f"ERROR: Failed to load JSON: {e}")
    sys.exit(1)
EOF

echo "SUCCESS: Valid JSON file!"

cat ${files_json_path}
