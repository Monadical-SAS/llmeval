#!/bin/bash
# Test that the output is valid JSON

if ! jq empty log_analysis.json 2>/dev/null; then
    echo "FAIL: log_analysis.json is not valid JSON"
    exit 1
fi

echo "PASS: log_analysis.json is valid JSON"
exit 0
