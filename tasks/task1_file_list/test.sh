#!/bin/bash

# Exit on any error
set -e

echo "Testing file list JSON creation..."

# Create a variable for the path of files.json
files_json_path="input/files.json"

# Check if files.json exists
if [ ! -f "$files_json_path" ]; then
    echo "ERROR: files.json not found!"
    exit 1
fi

# Check if it's valid JSON
if ! python3 -m json.tool "$files_json_path" > /dev/null 2>&1; then
    echo "ERROR: files.json is not valid JSON!"
    exit 1
fi

# Python script to validate the content
python3 << 'EOF'
import json
import os
import sys

# Expected files (relative paths)
expected_files = {
    "README.md",
    "main.py",
    ".gitignore",
    "requirements.txt",
    "Dockerfile",
    "config/settings.json",
    "scripts/build.sh",
    "src/components/App.jsx",
    "tests/unit/test_main.py",
    "docs/guide.md"
}

# Load the generated JSON
try:
    with open('input/files.json', 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f"ERROR: Failed to load files.json: {e}")
    sys.exit(1)

# Check structure
if not isinstance(data, dict):
    print("ERROR: JSON root must be an object")
    sys.exit(1)

if 'files' not in data:
    print("ERROR: JSON must have a 'files' key")
    sys.exit(1)

if not isinstance(data['files'], list):
    print("ERROR: 'files' value must be an array")
    sys.exit(1)

# Check if there are extra keys
if len(data.keys()) > 1:
    print("ERROR: JSON should only have 'files' key")
    sys.exit(1)

# Convert to set for comparison
actual_files = set(data['files'])

# Check for missing files
missing_files = expected_files - actual_files
if missing_files:
    print(f"ERROR: Missing files: {missing_files}")
    sys.exit(1)

# Check for extra files (excluding files.json itself)
extra_files = actual_files - expected_files
# Remove files.json if it's included (some solutions might include it)
extra_files.discard('files.json')
if extra_files:
    print(f"ERROR: Unexpected files: {extra_files}")
    sys.exit(1)

print("SUCCESS: All validation checks passed!")
print(f"Found {len(actual_files)} files as expected.")
EOF

echo "All tests passed!"
