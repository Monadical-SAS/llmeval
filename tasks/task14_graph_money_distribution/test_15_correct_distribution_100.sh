#!/bin/bash
# Test that the final distribution is exactly correct for 100 cents

# Expected: B1=0, B2=19, B3=9, B4=37, B5=20, B6=10, B7=3, B8=1, B9=1, B10=0
check_value() {
    key="$1"
    expected="$2"
    actual=$(jq -r ".[\"$key\"]" input/result_100.json 2>/dev/null)
    if [ "$actual" != "$expected" ]; then
        echo "FAIL: $key: expected $expected, got $actual"
        exit 1
    fi
}

check_value "B1" "0"
check_value "B2" "19"
check_value "B3" "9"
check_value "B4" "37"
check_value "B5" "20"
check_value "B6" "10"
check_value "B7" "3"
check_value "B8" "1"
check_value "B9" "1"
check_value "B10" "0"

echo "PASS: All beneficiary amounts correct in result_100.json"
exit 0
