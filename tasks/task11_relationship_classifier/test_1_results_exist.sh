#!/bin/bash
# Test 1: Check if results.json exists and is valid JSON
set -e

echo "Test 1: Checking if results.json exists and is valid..."

results_path="input/results.json"

if [ ! -f "$results_path" ]; then
    echo "ERROR: results.json not found at $results_path!"
    echo "The task requires creating a results.json file in the input directory."
    exit 1
fi

echo "SUCCESS: results.json exists!"

# Check file is not empty
if [ ! -s "$results_path" ]; then
    echo "ERROR: results.json exists but is empty!"
    exit 1
fi

# Check if it's valid JSON
if ! python3 -c "import json; json.load(open('$results_path'))" 2>/dev/null; then
    echo "ERROR: results.json is not valid JSON!"
    exit 1
fi

echo "SUCCESS: results.json is valid JSON!"

# Check if it has the expected structure
if ! python3 -c "
import json
data = json.load(open('$results_path'))
assert 'classifications' in data, 'Missing classifications key'
assert isinstance(data['classifications'], list), 'classifications must be a list'
assert len(data['classifications']) == 20, f'Expected 20 classifications, got {len(data[\"classifications\"])}'
print(f'Found {len(data[\"classifications\"])} classifications')
" 2>&1; then
    echo "ERROR: results.json has invalid structure!"
    exit 1
fi

echo "SUCCESS: results.json has valid structure with 20 classifications!"
