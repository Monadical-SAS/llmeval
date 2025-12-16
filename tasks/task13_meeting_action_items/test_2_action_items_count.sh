#!/bin/bash
# Test 2: Verify number of action items for Michal is at least the same as ground truth
set -e

echo "Test 2: Verifying action items count for Michal..."

python3 << 'EOF'
import json
import sys
from pathlib import Path

# Get all ground truth files
ground_truth_dir = Path('ground_truth')
ground_truth_files = sorted(ground_truth_dir.glob('*.json'))

if not ground_truth_files:
    print("ERROR: No ground truth files found!")
    sys.exit(1)

print(f"Found {len(ground_truth_files)} ground truth file(s)\n")

all_pass = True
total_files = 0
passing_files = 0

for gt_file in ground_truth_files:
    output_file = Path('input') / gt_file.name
    total_files += 1

    if not output_file.exists():
        print(f"❌ {gt_file.name}: Output file not found")
        all_pass = False
        continue

    # Load both files
    try:
        with open(gt_file) as f:
            gt_data = json.load(f)
        with open(output_file) as f:
            output_data = json.load(f)
    except Exception as e:
        print(f"❌ {gt_file.name}: Failed to load JSON: {e}")
        all_pass = False
        continue

    # Count action items
    gt_count = len(gt_data.get('action_items', []))
    output_count = len(output_data.get('action_items', []))

    # Check if output has at least as many action items as ground truth
    if output_count >= gt_count:
        print(f"✓ {gt_file.name}: Action items count OK (ground truth: {gt_count}, output: {output_count})")
        passing_files += 1
    else:
        print(f"❌ {gt_file.name}: Insufficient action items")
        print(f"    Expected at least {gt_count}, got {output_count}")
        all_pass = False

print("\n" + "="*60)
print(f"Results: {passing_files}/{total_files} files pass")
print("="*60)

if all_pass:
    print("SUCCESS: All files have sufficient action items for Michal!")
    sys.exit(0)
else:
    print("FAILED: Some files have insufficient action items")
    sys.exit(1)
EOF
