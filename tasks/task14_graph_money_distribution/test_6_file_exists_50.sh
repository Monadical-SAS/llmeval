#!/bin/bash
# Test that result_50.json exists

if [ ! -f "input/result_50.json" ]; then
    echo "FAIL: result_50.json not found"
    exit 1
fi

echo "PASS: result_50.json exists"
exit 0
