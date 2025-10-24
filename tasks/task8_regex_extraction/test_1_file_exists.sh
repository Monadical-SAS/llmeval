#!/bin/bash
# Test that the output file exists

if [ ! -f "input/extracted_data.json" ]; then
    echo "FAIL: extracted_data.json not found in input/ directory"
    exit 1
fi

echo "PASS: extracted_data.json exists"
exit 0
