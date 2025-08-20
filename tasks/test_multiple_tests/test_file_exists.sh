#!/bin/bash
set -e

echo "Test 1: Checking if files exist..."

if [ ! -f "input/calculator.py" ]; then
    echo "ERROR: calculator.py not found!"
    exit 1
fi

if [ ! -f "input/main.py" ]; then
    echo "ERROR: main.py not found!"
    exit 1
fi

echo "SUCCESS: All required files exist!"