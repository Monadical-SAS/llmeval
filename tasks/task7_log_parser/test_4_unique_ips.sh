#!/bin/bash
# Test that unique IPs are correctly extracted

unique_ips=$(jq -r '.unique_ips | length' log_analysis.json)

# There are 8 unique IPs in the log file
if [ "$unique_ips" != "8" ]; then
    echo "FAIL: Expected 8 unique IPs, got $unique_ips"
    exit 1
fi

# Check that specific IPs are present
if ! jq -e '.unique_ips | index("192.168.1.100")' log_analysis.json > /dev/null; then
    echo "FAIL: Expected IP 192.168.1.100 not found"
    exit 1
fi

if ! jq -e '.unique_ips | index("10.0.0.45")' log_analysis.json > /dev/null; then
    echo "FAIL: Expected IP 10.0.0.45 not found"
    exit 1
fi

echo "PASS: Unique IPs are correctly extracted"
exit 0
