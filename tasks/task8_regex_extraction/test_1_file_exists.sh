#!/bin/bash
# Test that the output file exists

if [ ! -f "extracted_data.json" ]; then
    echo "FAIL: extracted_data.json not found"
    exit 1
fi

echo "PASS: extracted_data.json exists"
exit 0
