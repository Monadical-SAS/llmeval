#!/bin/bash
# Test that emails are correctly extracted

email_count=$(jq -r '.emails | length' input/extracted_data.json)

# There are 8 email addresses in the file
if [ "$email_count" -lt "10" ]; then
    echo "FAIL: Expected at least 10 emails, got $email_count"
    exit 1
fi

# Check for specific emails
if ! jq -e '.emails | index("john.doe@example.com")' input/extracted_data.json > /dev/null; then
    echo "FAIL: Expected email john.doe@example.com not found"
    exit 1
fi

if ! jq -e '.emails | index("tech-support@example.com")' input/extracted_data.json > /dev/null; then
    echo "FAIL: Expected email tech-support@example.com not found"
    exit 1
fi

echo "PASS: Email extraction is correct"
exit 0
