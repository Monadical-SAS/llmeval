#!/bin/bash

# Exit on any error
set -e

echo "Testing team.json file..."

# Check if input directory exists
if [ ! -d "input" ]; then
    echo "ERROR: input directory not found!"
    exit 1
fi

# Check if team.json exists in input directory
if [ ! -f "input/team.json" ]; then
    echo "ERROR: input/team.json not found!"
    exit 1
fi

# Check if it's valid JSON
if ! python3 -m json.tool input/team.json > /dev/null 2>&1; then
    echo "ERROR: input/team.json is not valid JSON!"
    exit 1
fi

# Python script to validate the content
python3 << 'EOF'
import json
import sys

# Expected team members (first names from Monadical's team page)
expected_team = {
    "Max", "Nick", "Ana", "Juan Diego", "Milton", "Jose", "Tess", 
    "Juan David", "Kevin", "David", "Michał", "Joyce", "Igor", 
    "Sergey", "Kan", "Sebastian", "Jordan", "Mathieu", "Carly", 
    "Arman", "Nikita"
}

# Load the generated JSON
try:
    with open('input/team.json', 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f"ERROR: Failed to load input/team.json: {e}")
    sys.exit(1)

# Check structure
if not isinstance(data, dict):
    print("ERROR: JSON root must be an object")
    sys.exit(1)

if 'team' not in data:
    print("ERROR: JSON must have a 'team' key")
    sys.exit(1)

if not isinstance(data['team'], list):
    print("ERROR: 'team' value must be an array")
    sys.exit(1)

# Check if there are extra keys
if len(data.keys()) > 1:
    print("ERROR: JSON should only have 'team' key")
    sys.exit(1)

# Convert to set for comparison
actual_team = set(data['team'])

# Check for missing names
missing_names = expected_team - actual_team
if missing_names:
    print(f"ERROR: Missing team members: {missing_names}")
    sys.exit(1)

# Check for extra names
extra_names = actual_team - expected_team
if extra_names:
    print(f"WARNING: Extra team members found: {extra_names}")
    # Don't fail for extra names as the team might have grown

print("SUCCESS: All validation checks passed!")
print(f"Found {len(actual_team)} team members.")
print(f"Team members: {sorted(actual_team)}")
EOF

echo "All tests passed!"