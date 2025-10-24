#!/bin/bash
set -e

cd input

echo "Test: unsigned_underflow.cpp"

# Compile using Docker
docker run --rm -v "$PWD:/work" -w /work gcc:13 g++ -std=c++17 unsigned_underflow.cpp -o unsigned_test 2>&1

# Run using Docker
output=$(docker run --rm -v "$PWD:/work" -w /work gcc:13 ./unsigned_test 2>&1)

if ! echo "$output" | grep -q "Available: 3"; then
    echo "ERROR: Expected 'Available: 3'"
    exit 1
fi

if ! echo "$output" | grep -q "Empty: no"; then
    echo "ERROR: Expected 'Empty: no'"
    exit 1
fi

if ! echo "$output" | grep -q "Done"; then
    echo "ERROR: Expected 'Done'"
    exit 1
fi

rm -f unsigned_test
echo "PASS: unsigned_underflow.cpp"
