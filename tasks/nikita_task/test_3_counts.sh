#!/bin/bash
set -e

echo "Test 3: Validating counts..."

python3 << 'EOF'
import json
import sys

try:
    with open('input/deduped.json', 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f"ERROR: Failed to load input/deduped.json: {e}")
    sys.exit(1)

# Expected values
EXPECTED_ORIGINAL = 50
EXPECTED_UNIQUE = 42
EXPECTED_DUPLICATES = 8

# Check original count
if data['original_count'] != EXPECTED_ORIGINAL:
    print(f"ERROR: original_count is {data['original_count']}, expected {EXPECTED_ORIGINAL}")
    sys.exit(1)
print(f"✓ Original count correct: {data['original_count']}")

# Check unique count
if data['unique_count'] != EXPECTED_UNIQUE:
    print(f"ERROR: unique_count is {data['unique_count']}, expected {EXPECTED_UNIQUE}")
    sys.exit(1)
print(f"✓ Unique count correct: {data['unique_count']}")

# Check duplicates found
if data['duplicates_found'] != EXPECTED_DUPLICATES:
    print(f"ERROR: duplicates_found is {data['duplicates_found']}, expected {EXPECTED_DUPLICATES}")
    sys.exit(1)
print(f"✓ Duplicates found correct: {data['duplicates_found']}")

# Verify math: original_count = unique_count + duplicates_found
if data['original_count'] != data['unique_count'] + data['duplicates_found']:
    print(f"ERROR: Math doesn't add up: {data['original_count']} != {data['unique_count']} + {data['duplicates_found']}")
    sys.exit(1)
print("✓ Math checks out: original_count = unique_count + duplicates_found")

# Count duplicates in groups
total_duplicates_in_groups = sum(len(group['duplicates']) for group in data['duplicate_groups'])
if total_duplicates_in_groups != EXPECTED_DUPLICATES:
    print(f"ERROR: Total duplicates in groups is {total_duplicates_in_groups}, expected {EXPECTED_DUPLICATES}")
    sys.exit(1)
print(f"✓ Duplicate groups contain exactly {EXPECTED_DUPLICATES} duplicates")

print("SUCCESS: All counts are correct!")
EOF
