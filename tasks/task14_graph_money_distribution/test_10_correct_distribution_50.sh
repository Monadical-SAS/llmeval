#!/bin/bash
# Test that the final distribution is exactly correct for 50 cents

# Expected: B1=0, B2=10, B3=4, B4=19, B5=10, B6=4, B7=2, B8=1, B9=0, B10=0
check_value() {
    key="$1"
    expected="$2"
    actual=$(jq -r ".[\"$key\"]" input/result_50.json 2>/dev/null)
    if [ "$actual" != "$expected" ]; then
        echo "FAIL: $key: expected $expected, got $actual"
        exit 1
    fi
}

check_value "B1" "0"
check_value "B2" "10"
check_value "B3" "4"
check_value "B4" "19"
check_value "B5" "10"
check_value "B6" "4"
check_value "B7" "2"
check_value "B8" "1"
check_value "B9" "0"
check_value "B10" "0"

echo "PASS: All beneficiary amounts correct in result_50.json"
exit 0
