#!/bin/bash
# Test 3: Verify that files with no action items for Michal in ground truth also have no action items in output
set -e

echo "Test 3: Verifying empty cases (no false positives)..."

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
total_empty_cases = 0
passing_empty_cases = 0

for gt_file in ground_truth_files:
    output_file = Path('input') / gt_file.name

    if not output_file.exists():
        print(f"⚠️  {gt_file.name}: Output file not found, skipping")
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

    # Get action item counts
    gt_count = len(gt_data.get('action_items', []))
    output_count = len(output_data.get('action_items', []))

    # Only check cases where ground truth has 0 items
    if gt_count == 0:
        total_empty_cases += 1
        if output_count == 0:
            print(f"✓ {gt_file.name}: Correctly empty (no false positives)")
            passing_empty_cases += 1
        else:
            print(f"❌ {gt_file.name}: False positive detected!")
            print(f"    Ground truth: {gt_count} items")
            print(f"    Output: {output_count} items")
            print(f"    The LLM generated action items when there should be none for Michal")
            all_pass = False

if total_empty_cases == 0:
    print("\nℹ️  No empty cases in ground truth to validate")
    sys.exit(0)

print("\n" + "="*60)
print(f"Results: {passing_empty_cases}/{total_empty_cases} empty cases correct")
print("="*60)

if all_pass:
    print("SUCCESS: No false positives - empty cases are correctly empty!")
    sys.exit(0)
else:
    print("FAILED: Some files have false positives (generated items when there should be none)")
    sys.exit(1)
EOF
