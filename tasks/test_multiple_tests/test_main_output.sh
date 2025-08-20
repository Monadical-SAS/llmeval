#!/bin/bash
set -e

echo "Test 3: Testing main.py output..."

output=$(cd input && python3 main.py 2>&1)

if [[ "$output" == *"Calculator ready!"* ]]; then
    echo "SUCCESS: main.py prints the correct message!"
    echo "Output was: $output"
else
    echo "ERROR: main.py does not print 'Calculator ready!'"
    echo "Output was: $output"
    exit 1
fi

echo "Main output test passed!"