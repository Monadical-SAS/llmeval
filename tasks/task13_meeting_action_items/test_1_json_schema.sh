#!/bin/bash
# Test 1: Validate JSON schema for all output files
set -e

echo "Test 1: Validating JSON schema..."

# Check if ground_truth directory exists
if [ ! -d "ground_truth" ]; then
    echo "ERROR: ground_truth directory not found!"
    exit 1
fi

# Get list of expected output files
ground_truth_files=$(ls ground_truth/*.json 2>/dev/null || echo "")
if [ -z "$ground_truth_files" ]; then
    echo "ERROR: No ground truth files found in ground_truth/"
    exit 1
fi

python3 << 'EOF'
import json
import sys
import os
from datetime import datetime
from pathlib import Path

def validate_iso_datetime(value):
    """Validate ISO 8601 format datetime or date"""
    if value is None:
        return True
    try:
        datetime.fromisoformat(value)
        return True
    except (ValueError, TypeError):
        return False

def validate_action_item(item, index):
    """Validate a single action item"""
    errors = []

    # Check required fields
    if 'action_item' not in item:
        errors.append(f"  Action item {index}: Missing 'action_item' field")
    elif not isinstance(item['action_item'], str):
        errors.append(f"  Action item {index}: 'action_item' must be a string")

    if 'deadline' not in item:
        errors.append(f"  Action item {index}: Missing 'deadline' field")
    elif item['deadline'] is not None and not validate_iso_datetime(item['deadline']):
        errors.append(f"  Action item {index}: Invalid ISO 8601 deadline: '{item['deadline']}'")

    return errors

def validate_file(filepath):
    """Validate a single JSON file"""
    errors = []

    try:
        with open(filepath, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        return [f"Invalid JSON: {e}"]
    except Exception as e:
        return [f"Failed to read file: {e}"]

    # Validate top-level structure
    if not isinstance(data, dict):
        errors.append("Root must be an object")
        return errors

    if 'action_items' not in data:
        errors.append("Missing 'action_items' field")
    elif not isinstance(data['action_items'], list):
        errors.append("'action_items' must be an array")
    else:
        # Validate each action item
        for i, item in enumerate(data['action_items']):
            item_errors = validate_action_item(item, i)
            errors.extend(item_errors)

    return errors

# Get all ground truth files
ground_truth_dir = Path('ground_truth')
ground_truth_files = sorted(ground_truth_dir.glob('*.json'))

if not ground_truth_files:
    print("ERROR: No ground truth files found!")
    sys.exit(1)

print(f"Found {len(ground_truth_files)} ground truth file(s)")

# Validate each corresponding output file
all_valid = True
for gt_file in ground_truth_files:
    output_file = Path('input') / gt_file.name

    if not output_file.exists():
        print(f"\n❌ {gt_file.name}: Output file not found at {output_file}")
        all_valid = False
        continue

    errors = validate_file(output_file)

    if errors:
        print(f"\n❌ {gt_file.name}: Schema validation failed")
        for error in errors:
            print(f"  {error}")
        all_valid = False
    else:
        # Load and display summary
        with open(output_file) as f:
            data = json.load(f)
        print(f"✓ {gt_file.name}: Valid schema ({len(data['action_items'])} action items for Michal)")

if all_valid:
    print("\n" + "="*60)
    print("SUCCESS: All output files have valid JSON schema!")
    print("="*60)
    sys.exit(0)
else:
    print("\n" + "="*60)
    print("FAILED: Some files have schema validation errors")
    print("="*60)
    sys.exit(1)
EOF
