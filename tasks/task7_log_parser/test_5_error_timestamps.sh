#!/bin/bash
# Test that error timestamps are correctly extracted

error_count=$(jq -r '.error_timestamps | length' input/log_analysis.json)

if [ "$error_count" != "7" ]; then
    echo "FAIL: Expected 7 error timestamps, got $error_count"
    exit 1
fi

# Check for a specific error timestamp
if ! jq -e '.error_timestamps | index("2024-01-15 08:25:33")' input/log_analysis.json > /dev/null; then
    echo "FAIL: Expected timestamp 2024-01-15 08:25:33 not found"
    exit 1
fi

echo "PASS: Error timestamps are correctly extracted"
exit 0
