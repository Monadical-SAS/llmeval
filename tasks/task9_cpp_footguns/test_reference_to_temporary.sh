#!/bin/bash
set -e

cd input

echo "Test: reference_to_temporary.cpp"

# Compile using Docker
docker run --rm -v "$PWD:/work" -w /work gcc:13 g++ -std=c++17 -g reference_to_temporary.cpp -o ref_test 2>&1

# Run using Docker
output=$(docker run --rm -v "$PWD:/work" -w /work gcc:13 ./ref_test 2>&1)

if ! echo "$output" | grep -q "Application: MyApplication"; then
    echo "ERROR: Expected 'Application: MyApplication'"
    exit 1
fi

if ! echo "$output" | grep -q "Version: 2"; then
    echo "ERROR: Expected 'Version: 2'"
    exit 1
fi

if ! echo "$output" | grep -q "Done"; then
    echo "ERROR: Expected 'Done'"
    exit 1
fi

rm -f ref_test
echo "PASS: reference_to_temporary.cpp"
