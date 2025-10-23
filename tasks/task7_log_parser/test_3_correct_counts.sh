#!/bin/bash
# Test that error and warning counts are correct

total_errors=$(jq -r '.total_errors' log_analysis.json)
total_warnings=$(jq -r '.total_warnings' log_analysis.json)

if [ "$total_errors" != "7" ]; then
    echo "FAIL: Expected 7 errors, got $total_errors"
    exit 1
fi

if [ "$total_warnings" != "4" ]; then
    echo "FAIL: Expected 4 warnings, got $total_warnings"
    exit 1
fi

echo "PASS: Error and warning counts are correct"
exit 0
