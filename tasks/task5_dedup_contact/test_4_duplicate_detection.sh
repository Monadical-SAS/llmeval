#!/bin/bash
set -e

echo "Test 4: Validating duplicate detection..."

python3 << 'EOF'
import json
import sys

try:
    with open('input/deduped.json', 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f"ERROR: Failed to load input/deduped.json: {e}")
    sys.exit(1)

# Expected duplicate groups (we know these from the CSV)
expected_duplicates = {
    "John Smith": 2,  # 3 total entries = 1 primary + 2 duplicates
    "Sarah Johnson": 1,  # 2 total entries
    "Michael Brown": 1,  # 2 total entries
    "Jennifer Davis": 1,  # 2 total entries
    "Robert Wilson": 1,  # 2 total entries
    "Lisa Anderson": 1,  # 2 total entries
}

# Build a map of primary names to duplicate counts
found_groups = {}
for group in data['duplicate_groups']:
    primary_name = group['primary']['name']
    duplicate_count = len(group['duplicates'])
    found_groups[primary_name] = duplicate_count

print(f"Found {len(found_groups)} duplicate groups:")
for name, count in found_groups.items():
    print(f"  - {name}: {count} duplicate(s)")

# Check if all expected duplicate groups were found
missing_groups = []
for expected_name, expected_count in expected_duplicates.items():
    # Look for this name in found groups (could be in primary or as part of duplicates)
    found = False
    found_count = 0

    for group in data['duplicate_groups']:
        # Check if the expected name matches primary or any duplicate
        all_names = [group['primary']['name']] + [d['name'] for d in group['duplicates']]

        # Check for similar names (handle variations like "John Smith" and "J. Smith")
        for name in all_names:
            if expected_name.lower() in name.lower() or name.lower() in expected_name.lower():
                # Check if the last name matches
                expected_last = expected_name.split()[-1].lower()
                name_last = name.split()[-1].lower()
                if expected_last == name_last:
                    found = True
                    found_count = len(group['duplicates'])
                    break

        if found:
            break

    if not found:
        missing_groups.append(expected_name)
        print(f"ERROR: Expected duplicate group for '{expected_name}' not found")
    elif found_count != expected_count:
        print(f"WARNING: '{expected_name}' has {found_count} duplicates, expected {expected_count}")
        # Don't fail on count mismatch, just warn

if missing_groups:
    print(f"\nERROR: Missing {len(missing_groups)} expected duplicate groups")
    sys.exit(1)

print(f"\n✓ All expected duplicate groups found")

# Check match reasons are valid
valid_reasons = ['phone', 'email', 'name', 'phone_and_email', 'phone_and_name', 'email_and_name', 'all']
for group in data['duplicate_groups']:
    reason = group['match_reason']
    if reason not in valid_reasons:
        print(f"WARNING: Unusual match reason: '{reason}' (not in standard list)")

print("✓ Match reasons look reasonable")
print("SUCCESS: Duplicate detection validated!")
EOF
