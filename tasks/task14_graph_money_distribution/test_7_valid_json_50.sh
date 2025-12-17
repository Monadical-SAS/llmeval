#!/bin/bash
# Test that result_50.json is valid JSON

if ! jq empty input/result_50.json 2>/dev/null; then
    echo "FAIL: result_50.json is not valid JSON"
    exit 1
fi

echo "PASS: result_50.json is valid JSON"
exit 0
