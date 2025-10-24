#!/bin/bash
# Test that dates are correctly extracted

date_count=$(jq -r '.dates | length' input/extracted_data.json)

# There are 10 dates in the file (in various formats)
if [ "$date_count" -lt "12" ]; then
    echo "FAIL: Expected at least 12 dates, got $date_count"
    exit 1
fi

# Check that some dates are present (allowing for format variations)
dates=$(jq -r '.dates | join(" ")' input/extracted_data.json)

if [[ ! "$dates" =~ "2024-01-15" ]] && [[ ! "$dates" =~ "01/15/2024" ]]; then
    echo "FAIL: Expected to find date 2024-01-15 or 01/15/2024"
    exit 1
fi

echo "PASS: Date extraction is correct"
exit 0
