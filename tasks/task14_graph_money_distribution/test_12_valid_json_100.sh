#!/bin/bash
# Test that result_100.json is valid JSON

if ! jq empty input/result_100.json 2>/dev/null; then
    echo "FAIL: result_100.json is not valid JSON"
    exit 1
fi

echo "PASS: result_100.json is valid JSON"
exit 0
