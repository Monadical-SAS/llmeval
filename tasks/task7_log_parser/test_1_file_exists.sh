#!/bin/bash
# Test that the output file exists

if [ ! -f "log_analysis.json" ]; then
    echo "FAIL: log_analysis.json not found"
    exit 1
fi

echo "PASS: log_analysis.json exists"
exit 0
