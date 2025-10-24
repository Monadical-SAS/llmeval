#!/bin/bash
set -e

cd input

echo "Test: virtual_destructor.cpp"

# Compile with ASan using Docker
docker run --rm -v "$PWD:/work" -w /work gcc:13 g++ -std=c++17 -g -fsanitize=address -fno-omit-frame-pointer virtual_destructor.cpp -o vd_test 2>&1

# Run using Docker + check output and leaks
output=$(docker run --rm -v "$PWD:/work" -w /work gcc:13 ./vd_test 2>&1)

if ! echo "$output" | grep -q "ImageProcessor"; then
    echo "ERROR: Missing expected output 'ImageProcessor'"
    exit 1
fi

if ! echo "$output" | grep -q "Processing images"; then
    echo "ERROR: Missing expected output 'Processing images'"
    exit 1
fi

if ! echo "$output" | grep -q "Done"; then
    echo "ERROR: Missing expected output 'Done'"
    exit 1
fi

# Check for leaks (ASan will report if destructors not called)
if echo "$output" | grep -qi "leak"; then
    echo "ERROR: Memory leak detected"
    exit 1
fi

rm -f vd_test
echo "PASS: virtual_destructor.cpp"
