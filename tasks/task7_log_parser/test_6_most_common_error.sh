#!/bin/bash
# Test that the most common error is correctly identified

most_common=$(jq -r '.most_common_error' input/log_analysis.json)

# The most common error appears 3 times: "Database connection failed: timeout after 30s"
if [[ "$most_common" != *"Database connection failed"* ]]; then
    echo "FAIL: Most common error should contain 'Database connection failed', got: $most_common"
    exit 1
fi

echo "PASS: Most common error is correctly identified"
exit 0
