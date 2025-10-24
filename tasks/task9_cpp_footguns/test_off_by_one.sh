#!/bin/bash
set -e

cd input

echo "Test: off_by_one.cpp"

# Compile with ASan using Docker
docker run --rm -v "$PWD:/work" -w /work gcc:13 g++ -std=c++17 -g -fsanitize=address off_by_one.cpp -o off_test 2>&1

# Run using Docker
output=$(docker run --rm -v "$PWD:/work" -w /work gcc:13 ./off_test 2>&1)

if ! echo "$output" | grep -q "Top row: 0 1 2 3 4"; then
    echo "ERROR: Expected 'Top row: 0 1 2 3 4'"
    exit 1
fi

if ! echo "$output" | grep -q "Done"; then
    echo "ERROR: Expected 'Done'"
    exit 1
fi

# ASan should not report any errors
if echo "$output" | grep -qi "AddressSanitizer"; then
    echo "ERROR: AddressSanitizer violation"
    exit 1
fi

rm -f off_test
echo "PASS: off_by_one.cpp"
