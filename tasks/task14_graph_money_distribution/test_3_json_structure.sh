#!/bin/bash
# Test that result_5.json has all required beneficiary keys

for i in {1..10}; do
    key="B$i"
    value=$(jq -r ".[\"$key\"]" input/result_5.json 2>/dev/null)
    if [ "$value" == "null" ] || [ -z "$value" ]; then
        echo "FAIL: Missing key $key in result_5.json"
        exit 1
    fi
    # Check it's an integer
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "FAIL: $key value '$value' is not a non-negative integer"
        exit 1
    fi
done

echo "PASS: All beneficiary keys present with integer values in result_5.json"
exit 0
