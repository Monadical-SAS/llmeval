#!/bin/bash
# Test 2: Verify all classifications are correct
set -e

echo "Test 2: Verifying classifications against expected values..."

python3 << 'EOF'
import json
import sys

# Load results
with open('input/results.json') as f:
    results = json.load(f)

# Load expected values from test cases
with open('input/test_cases.json') as f:
    test_cases = json.load(f)

# Build lookup for results
result_lookup = {}
for item in results['classifications']:
    idx = item['case_index']
    result_lookup[idx] = item['knows_each_other']

# Compare each case
correct = 0
total = len(test_cases)
errors = []

for i, case in enumerate(test_cases):
    expected = case['knows_each_other']

    if i not in result_lookup:
        errors.append(f"Case {i}: Missing classification for {case['primary_name']} <-> {case['candidate_name']}")
        continue

    actual = result_lookup[i]

    # Handle string vs boolean
    if isinstance(actual, str):
        actual = actual.lower() == 'true'

    if actual == expected:
        correct += 1
        print(f"Case {i}: CORRECT - {case['primary_name']} <-> {case['candidate_name']} = {expected}")
    else:
        errors.append(f"Case {i}: WRONG - Expected {expected}, got {actual} ({case['primary_name']} <-> {case['candidate_name']})")

print(f"\n{'='*60}")
print(f"Results: {correct}/{total} correct ({100*correct/total:.1f}%)")
print(f"{'='*60}")

if errors:
    print("\nErrors:")
    for err in errors:
        print(f"  - {err}")

# Pass if at least 80% correct (16/20)
threshold = 0.8
if correct / total >= threshold:
    print(f"\nSUCCESS: Achieved {100*correct/total:.1f}% accuracy (threshold: {100*threshold:.0f}%)")
    sys.exit(0)
else:
    print(f"\nFAILED: Only {100*correct/total:.1f}% accuracy (threshold: {100*threshold:.0f}%)")
    sys.exit(1)
EOF
