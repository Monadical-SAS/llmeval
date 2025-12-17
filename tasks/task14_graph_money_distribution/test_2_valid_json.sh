#!/bin/bash
# Test that result_5.json is valid JSON

if ! jq empty input/result_5.json 2>/dev/null; then
    echo "FAIL: result_5.json is not valid JSON"
    exit 1
fi

echo "PASS: result_5.json is valid JSON"
exit 0
