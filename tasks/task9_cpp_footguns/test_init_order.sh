#!/bin/bash
set -e

cd input

echo "Test: init_order.cpp"

# Compile with UBSan using Docker
docker run --rm -v "$PWD:/work" -w /work gcc:13 g++ -std=c++17 -g -fsanitize=undefined init_order.cpp -o init_test 2>&1

# Run using Docker
output=$(docker run --rm -v "$PWD:/work" -w /work gcc:13 ./init_test 2>&1)

if ! echo "$output" | grep -q "Point(6, 8) scale=2"; then
    echo "ERROR: Expected 'Point(6, 8) scale=2'"
    exit 1
fi

if ! echo "$output" | grep -q "Done"; then
    echo "ERROR: Expected 'Done'"
    exit 1
fi

rm -f init_test
echo "PASS: init_order.cpp"
