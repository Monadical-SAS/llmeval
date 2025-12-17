#!/bin/bash
# Test that result_5.json exists

if [ ! -f "input/result_5.json" ]; then
    echo "FAIL: result_5.json not found"
    exit 1
fi

echo "PASS: result_5.json exists"
exit 0
