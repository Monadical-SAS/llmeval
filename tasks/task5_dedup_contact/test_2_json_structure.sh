#!/bin/bash
set -e

echo "Test 2: Validating JSON structure..."

python3 << 'EOF'
import json
import sys

try:
    with open('input/deduped.json', 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f"ERROR: Failed to load input/deduped.json: {e}")
    sys.exit(1)

# Check required top-level keys
required_keys = ['original_count', 'unique_count', 'duplicates_found', 'duplicate_groups']
for key in required_keys:
    if key not in data:
        print(f"ERROR: Missing required key: {key}")
        sys.exit(1)

print(f"✓ All required keys present: {required_keys}")

# Check types
if not isinstance(data['original_count'], int):
    print(f"ERROR: original_count must be an integer")
    sys.exit(1)

if not isinstance(data['unique_count'], int):
    print(f"ERROR: unique_count must be an integer")
    sys.exit(1)

if not isinstance(data['duplicates_found'], int):
    print(f"ERROR: duplicates_found must be an integer")
    sys.exit(1)

if not isinstance(data['duplicate_groups'], list):
    print(f"ERROR: duplicate_groups must be an array")
    sys.exit(1)

print("✓ All field types correct")

# Check each duplicate group structure
for i, group in enumerate(data['duplicate_groups']):
    if 'primary' not in group:
        print(f"ERROR: Duplicate group {i} missing 'primary' key")
        sys.exit(1)

    if 'duplicates' not in group:
        print(f"ERROR: Duplicate group {i} missing 'duplicates' key")
        sys.exit(1)

    if 'match_reason' not in group:
        print(f"ERROR: Duplicate group {i} missing 'match_reason' key")
        sys.exit(1)

    # Check primary contact structure
    primary = group['primary']
    required_contact_fields = ['name', 'email', 'phone', 'company']
    for field in required_contact_fields:
        if field not in primary:
            print(f"ERROR: Primary contact in group {i} missing field: {field}")
            sys.exit(1)

    # Check duplicates list
    if not isinstance(group['duplicates'], list):
        print(f"ERROR: Duplicates in group {i} must be an array")
        sys.exit(1)

    if len(group['duplicates']) == 0:
        print(f"ERROR: Duplicate group {i} has no duplicates listed")
        sys.exit(1)

print(f"✓ All {len(data['duplicate_groups'])} duplicate groups have correct structure")
print("SUCCESS: JSON structure is valid")
EOF
