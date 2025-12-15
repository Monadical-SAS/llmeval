# Need Reply Classification Task

You are an AI assistant helping a user manage their conversations. Your task is to analyze conversation threads and determine if they require a response from the user.

## User Context

- **User ID**: 4
- **User Name**: Mathieu Virbel
- **Team Membership**: reflector team

## Task

For each conversation file in this directory (`convXXX.json`) in the current directory, analyze the conversation and create a corresponding classification file.

### Input Format

Each `convN.json` file contains a conversation with:
- `id`: Unique conversation identifier
- `contact_ids`: List of participant contact IDs
- `title`: Conversation title
- `recent_messages`: Array of messages, each with:
  - `content`: Message text (may contain @mentions in Zulip format like `@**Name**` or `@*group*`)
  - `sender_contact_id`: ID of the message sender
  - `timestamp`: Unix timestamp

### Output Format

For each `convN.json`, create a `convN_classification.json` file with:
```json
{
  "need_reply": true/false,
  "reason": "Brief explanation of why the user does or doesn't need to reply"
}
```

### Classification Rules

The user needs to reply (`need_reply: true`) if ANY of these conditions are met:
1. The user is directly mentioned
2. A team the user belongs to is mentioned
3. The last message(s) are from someone else and appear to be directed at or waiting for the user (e.g., questions in an active exchange with the user)

The user does NOT need to reply (`need_reply: false`) if:
1. The user sent the last message(s) and the conversation appears concluded
2. The conversation doesn't involve or mention the user
3. No action or response is expected from the user

### Important Notes

- Messages are ordered by timestamp (most recent first in the array)
- Look at the conversation flow to understand if someone is waiting for a response
- Consider the context of the full conversation, not just individual messages

PS: You are currently working in an automated system and cannot ask any question or have back and forth with a user.
