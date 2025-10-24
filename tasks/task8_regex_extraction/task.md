You'll find a text file called `mixed_content.txt` in the `./input` directory containing various types of data mixed
together.

Extract ALL instances of the following patterns using regular expressions:

- Email addresses
- Phone numbers (various formats: (123) 456-7890, 123-456-7890, 123.456.7890)
- URLs (http and https)
- Dates (formats: YYYY-MM-DD, MM/DD/YYYY, DD-MM-YYYY)

Generate a JSON file called `extracted_data.json` with the following structure:

```json
{
  "emails": [
    "email1@example.com",
    "email2@example.com",
    ...
  ],
  "phone_numbers": [
    "(123) 456-7890",
    "123-456-7890",
    ...
  ],
  "urls": [
    "https://example.com",
    "http://example.org",
    ...
  ],
  "dates": [
    "2024-01-15",
    "01/15/2024",
    ...
  ]
}
```

Each array should contain the extracted values in the order they appear in the file. Duplicates should be included if they appear multiple times.

PS: You are currently working in an automated system and cannot ask any question or have back and forth with an user.
