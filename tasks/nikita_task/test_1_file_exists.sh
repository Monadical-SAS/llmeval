#!/bin/bash
set -e

echo "Test 1: Checking if deduped.json exists..."

if [ ! -f "input/deduped.json" ]; then
    echo "ERROR: input/deduped.json not found!"
    exit 1
fi

echo "✓ File exists"

# Check if it's valid JSON
if ! python3 -m json.tool input/deduped.json > /dev/null 2>&1; then
    echo "ERROR: input/deduped.json is not valid JSON!"
    exit 1
fi

echo "✓ Valid JSON format"
echo "SUCCESS: File exists and is valid JSON"
