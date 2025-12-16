#!/bin/bash
# Test that result_100.json exists

if [ ! -f "input/result_100.json" ]; then
    echo "FAIL: result_100.json not found"
    exit 1
fi

echo "PASS: result_100.json exists"
exit 0
