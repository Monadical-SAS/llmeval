#!/bin/bash
# Test that total money sums to 50 cents (conservation of money)

total=0
for i in {1..10}; do
    value=$(jq -r ".B$i" input/result_50.json 2>/dev/null)
    total=$((total + value))
done

if [ "$total" != "50" ]; then
    echo "FAIL: Total money is $total, expected 50 (money must be conserved)"
    exit 1
fi

echo "PASS: Total money is correctly 50 cents in result_50.json"
exit 0
