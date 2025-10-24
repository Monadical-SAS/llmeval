#!/bin/bash
set -e

cd input

echo "Test: int_overflow.cpp"

# Compile with UBSan using Docker
docker run --rm -v "$PWD:/work" -w /work gcc:13 g++ -std=c++17 -g -fsanitize=undefined int_overflow.cpp -o overflow_test 2>&1

# Run using Docker
output=$(docker run --rm -v "$PWD:/work" -w /work gcc:13 ./overflow_test 2>&1)

if ! echo "$output" | grep -q "Price: \$10 x 5 = \$50"; then
    echo "ERROR: Expected 'Price: \$10 x 5 = \$50'"
    exit 1
fi

if ! echo "$output" | grep -q "Price: \$100000 x 50000 = \$5000000000"; then
    echo "ERROR: Expected 'Price: \$100000 x 50000 = \$5000000000'"
    exit 1
fi

if ! echo "$output" | grep -q "Done"; then
    echo "ERROR: Expected 'Done'"
    exit 1
fi

# UBSan should not report overflow
if echo "$output" | grep -qi "runtime error"; then
    echo "ERROR: UndefinedBehaviorSanitizer violation"
    exit 1
fi

rm -f overflow_test
echo "PASS: int_overflow.cpp"
