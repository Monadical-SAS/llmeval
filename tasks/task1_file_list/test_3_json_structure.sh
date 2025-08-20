#!/bin/bash

# Test 3: Check JSON structure (must have 'files' key with array value)
set -e

echo "Test 3: Validating JSON structure..."

python3 << 'EOF'
import json
import sys

# Load the JSON
try:
    with open('input/files.json', 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f"ERROR: Failed to load files.json: {e}")
    sys.exit(1)

# Check that root is a dictionary/object
if not isinstance(data, dict):
    print(f"ERROR: JSON root must be an object/dictionary")
    print(f"  Found type: {type(data).__name__}")
    print("  Expected: dict/object with 'files' key")
    sys.exit(1)
print("✓ Root is an object")

# Check for 'files' key
if 'files' not in data:
    print("ERROR: JSON must have a 'files' key")
    print(f"  Keys found: {list(data.keys())}")
    print("  Expected: {'files': [...]}")
    sys.exit(1)
print("✓ Has 'files' key")

# Check that 'files' value is an array
if not isinstance(data['files'], list):
    print(f"ERROR: 'files' value must be an array")
    print(f"  Found type: {type(data['files']).__name__}")
    print("  Expected: array/list of file paths")
    sys.exit(1)
print("✓ 'files' value is an array")

# Check for extra keys (warn but don't fail)
extra_keys = set(data.keys()) - {'files'}
if extra_keys:
    print(f"WARNING: JSON has extra keys that will be ignored: {extra_keys}")
    print("  Recommended: Use only the 'files' key")

# Check array contents are strings
non_strings = [i for i, item in enumerate(data['files']) if not isinstance(item, str)]
if non_strings:
    print(f"ERROR: All items in 'files' array must be strings")
    print(f"  Non-string items at indices: {non_strings}")
    sys.exit(1)
print("✓ All array items are strings")

print(f"SUCCESS: JSON structure is correct!")
print(f"  Found {len(data['files'])} file entries")
EOF