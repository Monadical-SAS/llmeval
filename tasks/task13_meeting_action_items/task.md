# Meeting Action Items Extraction for Michal

You are analyzing meeting transcripts to extract action items specifically for a person named **Michal**.

## Input Files

The `input/` directory contains JSON files with meeting transcripts. Each file has the following structure:

- `title` - Meeting title
- `timestamp` - Meeting date in ISO format
- `raw_data.room_name` - Room/channel name
- `raw_data.short_summary` - Brief summary
- `raw_data.long_summary` - Detailed summary
- `raw_data.transcript` - Full conversation transcript

## Your Task

For each JSON file in the `input/` directory, extract **all action items assigned to or involving Michal**.

Check for variations like "Michal", "michal", "Michael", "Michał".

## Output Format

Create corresponding JSON files in the current directory with the same names as the input files (e.g., `1.json`, `2.json`, etc.).

Each output file must follow this exact schema:

```json
{
  "action_items": [
    {"action_item": "Description of task for Michal", "deadline": null},
    {"action_item": "Another task with date", "deadline": "2025-12-20"},
    {"action_item": "Task with datetime", "deadline": "2025-12-20T10:00:00"}
  ]
}
```

## Action Item Fields

- **action_item**: A clear description of what Michal needs to do
- **deadline**: Any mentioned deadline in ISO 8601 format (e.g., "2025-12-20" or "2025-12-20T10:00:00"), or null if not specified

## Important Guidelines

- **Be conservative**. Only create an action item if you're sure it stems from the conversation and is clearly assigned to or involves Michal.
- Include all commitments, tasks, and follow-ups for Michal that are explicitly mentioned in the meeting.
- Deadlines must be in valid ISO 8601 format (date only like "2025-12-20" or full datetime like "2025-12-20T10:00:00")
- If Michal has no action items in a meeting, return an empty action_items array: `{"action_items": []}`

PS: You are currently working in an automated system and cannot ask any questions or have back and forth with a user.
