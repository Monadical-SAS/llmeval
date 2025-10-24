#!/bin/bash
# Test that phone numbers are correctly extracted

phone_count=$(jq -r '.phone_numbers | length' input/extracted_data.json)

# There are 7 phone numbers in the file
if [ "$phone_count" -lt "7" ]; then
    echo "FAIL: Expected at least 7 phone numbers, got $phone_count"
    exit 1
fi

# Check for specific phone formats (allowing some flexibility in extraction)
phones=$(jq -r '.phone_numbers | join(" ")' input/extracted_data.json)

if [[ ! "$phones" =~ "555" ]]; then
    echo "FAIL: Phone numbers should contain '555' area code"
    exit 1
fi

echo "PASS: Phone number extraction is correct"
exit 0
