#!/bin/bash
# Test that the output is valid JSON with required fields

if ! jq empty input/extracted_data.json 2>/dev/null; then
    echo "FAIL: extracted_data.json is not valid JSON"
    exit 1
fi

# Check for required fields
for field in emails phone_numbers urls dates; do
    if ! jq -e ".$field" input/extracted_data.json > /dev/null 2>&1; then
        echo "FAIL: Missing required field: $field"
        exit 1
    fi
done

echo "PASS: extracted_data.json is valid JSON with all required fields"
exit 0
