#!/bin/bash
# Test that total money sums to 100 cents (conservation of money)

total=0
for i in {1..10}; do
    value=$(jq -r ".B$i" input/result_100.json 2>/dev/null)
    total=$((total + value))
done

if [ "$total" != "100" ]; then
    echo "FAIL: Total money is $total, expected 100 (money must be conserved)"
    exit 1
fi

echo "PASS: Total money is correctly 100 cents in result_100.json"
exit 0
