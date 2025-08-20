#!/bin/bash

# Test 4: Check that all expected files are listed
set -e

echo "Test 4: Validating expected file content..."

python3 << 'EOF'
import json
import sys

# Expected files that must be present
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

# Load the JSON
try:
    with open('input/files.json', 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f"ERROR: Failed to load files.json: {e}")
    sys.exit(1)

# Normalize paths by removing leading './' from all entries
def normalize_path(path):
    """Remove leading './' from path to normalize it."""
    if path.startswith('./'):
        return path[2:]
    return path

# Get the actual files list and normalize paths
actual_files_raw = data['files']
actual_files_normalized = [normalize_path(f) for f in actual_files_raw]
actual_files = set(actual_files_normalized)

print(f"Expected {len(expected_files)} files")
print(f"Found {len(actual_files)} unique normalized files in JSON")

# Check for missing files
missing_files = expected_files - actual_files
if missing_files:
    print(f"\nERROR: Missing required files:")
    for file in sorted(missing_files):
        print(f"  - {file}")
    print(f"\nTotal missing: {len(missing_files)}")
    sys.exit(1)
else:
    print("✓ All required files are present")

# Check for extra files (excluding files.json itself)
extra_files = actual_files - expected_files
# Remove files.json if it's included (some solutions might include it)
extra_files.discard('files.json')
extra_files.discard('input/files.json')

if extra_files:
    print(f"\nERROR: Unexpected extra files found:")
    for file in sorted(extra_files):
        print(f"  - {file}")
    print(f"\nTotal unexpected: {len(extra_files)}")
    print("\nNote: The JSON should contain exactly the files listed in the input directory")
    sys.exit(1)
else:
    print("✓ No unexpected files")

# Check for duplicates (using normalized paths)
if len(actual_files) != len(actual_files_normalized):
    print(f"\nWARNING: Duplicate entries detected")
    print(f"  Array length: {len(actual_files_normalized)}")
    print(f"  Unique files: {len(actual_files)}")
    from collections import Counter
    counts = Counter(actual_files_normalized)
    duplicates = {file: count for file, count in counts.items() if count > 1}
    if duplicates:
        print("  Duplicated files:")
        for file, count in duplicates.items():
            print(f"    - {file}: appears {count} times")

print(f"\nSUCCESS: All expected files are correctly listed!")
print(f"✓ {len(expected_files)} files validated")

# Display the files for verification
print("\nFiles found:")
for file in sorted(actual_files):
    print(f"  ✓ {file}")
EOF