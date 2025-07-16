#!/bin/bash

# Exit on any error
set -e

echo "Testing Python syntax fixes..."

# Check if input directory exists
if [ ! -d "input" ]; then
    echo "ERROR: input directory not found!"
    exit 1
fi

# Test each Python file for syntax errors
error_count=0
file_count=0

for file in input/file*.py; do
    if [ -f "$file" ]; then
        file_count=$((file_count + 1))
        echo "Checking syntax of $file..."
        
        if python -m py_compile "$file"; then
            echo "✓ $file: Syntax OK"
        else
            echo "✗ $file: Syntax ERROR"
            error_count=$((error_count + 1))
        fi
    fi
done

echo ""
echo "Summary:"
echo "Total files checked: $file_count"
echo "Files with syntax errors: $error_count"

if [ $error_count -eq 0 ]; then
    echo "SUCCESS: All Python files have correct syntax!"
    exit 0
else
    echo "FAILURE: $error_count file(s) still have syntax errors"
    exit 1
fi