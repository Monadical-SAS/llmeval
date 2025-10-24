#!/bin/bash
# Test that URLs are correctly extracted

url_count=$(jq -r '.urls | length' input/extracted_data.json)

# There are 7 URLs in the file
if [ "$url_count" -lt "7" ]; then
    echo "FAIL: Expected at least 7 URLs, got $url_count"
    exit 1
fi

# Check for specific URLs
if ! jq -e '.urls | index("https://app.example.com")' input/extracted_data.json > /dev/null; then
    echo "FAIL: Expected URL https://app.example.com not found"
    exit 1
fi

if ! jq -e '.urls | index("http://help.example.org/articles/login-issues")' input/extracted_data.json > /dev/null; then
    echo "FAIL: Expected URL http://help.example.org/articles/login-issues not found"
    exit 1
fi

echo "PASS: URL extraction is correct"
exit 0
