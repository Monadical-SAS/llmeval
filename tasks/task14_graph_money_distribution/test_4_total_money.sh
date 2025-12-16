#!/bin/bash
# Test that total money sums to 5 cents (conservation of money)

total=0
for i in {1..10}; do
    value=$(jq -r ".B$i" input/result_5.json 2>/dev/null)
    total=$((total + value))
done

if [ "$total" != "5" ]; then
    echo "FAIL: Total money is $total, expected 5 (money must be conserved)"
    exit 1
fi

echo "PASS: Total money is correctly 5 cents in result_5.json"
exit 0
