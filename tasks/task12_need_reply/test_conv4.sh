#!/bin/bash
set -e

echo "Test: Checking conv4_classification.json..."

FILE="input/conv4_classification.json"

if [ ! -f "$FILE" ]; then
    echo "ERROR: conv4_classification.json not found!"
    exit 1
fi

# Check if it's valid JSON
if ! python3 -c "import json; json.load(open('$FILE'))" 2>/dev/null; then
    echo "ERROR: conv4_classification.json is not valid JSON!"
    exit 1
fi

# Check for required fields and expected value
python3 << 'EOF'
import json
import sys

with open("input/conv4_classification.json") as f:
    data = json.load(f)

if "need_reply" not in data:
    print("ERROR: 'need_reply' field is missing!")
    sys.exit(1)

if "reason" not in data:
    print("ERROR: 'reason' field is missing!")
    sys.exit(1)

if not isinstance(data["reason"], str) or len(data["reason"]) < 5:
    print("ERROR: 'reason' should be a meaningful string explanation!")
    sys.exit(1)

# Conv4 SHOULD require a reply
if data["need_reply"] != True:
    print(f"ERROR: need_reply should be true for conv4, got: {data['need_reply']}")
    print(f"Reason given: {data['reason']}")
    sys.exit(1)

print(f"SUCCESS: conv4 correctly classified as needing reply")
print(f"Reason: {data['reason']}")
EOF

echo "conv4 classification test passed!"
