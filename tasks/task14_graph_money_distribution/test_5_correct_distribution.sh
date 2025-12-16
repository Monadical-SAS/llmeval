#!/bin/bash
# Test that the final distribution is exactly correct for 5 cents

# Expected values: B1=0, B2=1, B3=1, B4=2, B5=1, B6-B10=0
check_value() {
    key="$1"
    expected="$2"
    actual=$(jq -r ".[\"$key\"]" input/result_5.json 2>/dev/null)
    if [ "$actual" != "$expected" ]; then
        echo "FAIL: $key: expected $expected, got $actual"
        exit 1
    fi
}

check_value "B1" "0"
check_value "B2" "1"
check_value "B3" "1"
check_value "B4" "2"
check_value "B5" "1"
check_value "B6" "0"
check_value "B7" "0"
check_value "B8" "0"
check_value "B9" "0"
check_value "B10" "0"

echo "PASS: All beneficiary amounts correct in result_5.json"
exit 0
