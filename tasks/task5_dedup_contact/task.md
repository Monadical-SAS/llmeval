# Contact List Deduplicator

You have a CSV file `input/contacts.csv` containing contact information with potential duplicates.

Your task is to identify and merge duplicate contacts based on matching criteria, then generate a JSON report.

## Duplicate Detection Rules

Two contacts are duplicates if ANY of the following match:
1. **Phone numbers match** (after normalization - remove spaces, dashes, parentheses)
2. **Email addresses match** (case-insensitive)
3. **Names are very similar** (exact match ignoring case, or initials match with same last name)

## Requirements

1. Read `input/contacts.csv`
2. Identify all duplicate contacts
3. Generate `input/deduped.json` with this exact structure:

```json
{
  "original_count": 100,
  "unique_count": 85,
  "duplicates_found": 15,
  "duplicate_groups": [
    {
      "primary": {
        "name": "John Smith",
        "email": "john.smith@example.com",
        "phone": "555-1234",
        "company": "Acme Corp"
      },
      "duplicates": [
        {
          "name": "J. Smith",
          "email": "jsmith@example.com",
          "phone": "555-1234",
          "company": "Acme Corp"
        }
      ],
      "match_reason": "phone"
    }
  ]
}
```

## Important Notes

- The primary contact should be the one with the most complete information (fewest empty fields)
- Normalize phone numbers before comparison: remove all spaces, dashes, and parentheses
- Email matching should be case-insensitive
- Match reasons can be: "phone", "email", "name", or combinations like "phone_and_email"
- Each duplicate group should list the primary contact and all its duplicates
- Original count includes all contacts, unique count is after deduplication
- Duplicates found is the number of duplicate entries (not the number of groups)
