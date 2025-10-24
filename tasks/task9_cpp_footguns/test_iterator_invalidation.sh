#!/bin/bash
set -e

cd input

echo "Test: iterator_invalidation.cpp"

# Compile with ASan using Docker
docker run --rm -v "$PWD:/work" -w /work gcc:13 g++ -std=c++17 -g -fsanitize=address iterator_invalidation.cpp -o iter_test 2>&1

# Run using Docker
output=$(docker run --rm -v "$PWD:/work" -w /work gcc:13 ./iter_test 2>&1)

if ! echo "$output" | grep -q "Event: user_login"; then
    echo "ERROR: Expected 'Event: user_login'"
    exit 1
fi

if ! echo "$output" | grep -q "Event: page_view"; then
    echo "ERROR: Expected 'Event: page_view'"
    exit 1
fi

if ! echo "$output" | grep -q "Total events: 3"; then
    echo "ERROR: Expected 'Total events: 3'"
    exit 1
fi

if ! echo "$output" | grep -q "Done"; then
    echo "ERROR: Expected 'Done'"
    exit 1
fi

rm -f iter_test
echo "PASS: iterator_invalidation.cpp"
