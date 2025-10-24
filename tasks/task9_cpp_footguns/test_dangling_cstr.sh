#!/bin/bash
set -e

cd input

echo "Test: dangling_cstr.cpp"

# Compile using Docker to avoid macOS SDK conflicts
docker run --rm -v "$PWD:/work" -w /work gcc:13 g++ -std=c++17 dangling_cstr.cpp -o cstr_test 2>&1

# Run using Docker (since it's a Linux binary)
output=$(docker run --rm -v "$PWD:/work" -w /work gcc:13 ./cstr_test 2>&1)

if ! echo "$output" | grep -q "\[LOG\] System started"; then
    echo "ERROR: Expected '[LOG] System started'"
    exit 1
fi

if ! echo "$output" | grep -q "\[LOG\] Loading config"; then
    echo "ERROR: Expected '[LOG] Loading config'"
    exit 1
fi

if ! echo "$output" | grep -q "\[LOG\] Ready"; then
    echo "ERROR: Expected '[LOG] Ready'"
    exit 1
fi

if ! echo "$output" | grep -q "Done"; then
    echo "ERROR: Expected 'Done'"
    exit 1
fi

rm -f cstr_test
echo "PASS: dangling_cstr.cpp"
