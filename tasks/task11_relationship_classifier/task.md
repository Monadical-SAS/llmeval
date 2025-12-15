# Relationship Classifier Task

You are given a relationship classification prompt and a set of test cases. Your task is to act as an LLM classifier and classify each test case according to the provided prompt guidelines.

## Prompt Variables

| Variable                        | Type | Description                                             |
| ------------------------------- | ---- | ------------------------------------------------------- |
| `primary_name`                  | str  | Name of the primary profile                             |
| `primary_headline`              | str  | Title/headline of the primary profile                   |
| `primary_bio`                   | str  | Bio of the primary profile                              |
| `candidate_name`                | str  | Name of the candidate profile                           |
| `candidate_headline`            | str  | Title/headline of the candidate profile                 |
| `candidate_bio`                 | str  | Bio of the candidate profile                            |
| `interaction_type`              | str  | Either "candidate_on_primary" or "primary_on_candidate" |
| `post_text`                     | str  | The post content (truncated to 500 chars)               |
| `comment_text`                  | str  | The comment content                                     |
| `engagement.totalReactionCount` | int  | Number of reactions on the post                         |
| `engagement.totalComments`      | int  | Number of comments/replies on the post                  |

## Instructions

1. Read the `classifier_prompt.md` file to understand the classification criteria
2. Read the `test_cases.json` file containing 20 LinkedIn interaction scenarios
3. For each test case, determine whether the two people **know each other personally** based on:

   - The profiles of both people
   - The interaction type (who commented on whose post)
   - The post content
   - The comment content
   - The engagement metrics

4. Output your classifications to a file named `results.json` with the following format:

```json
{
  "classifications": [
    {"case_index": 0, "knows_each_other": true},
    {"case_index": 1, "knows_each_other": false},
    ...
  ]
}
```

The `case_index` should match the index of each test case in the `test_cases.json` array (0-indexed).

## Key Classification Guidelines (from the prompt)

**Strong Evidence (suggests they know each other):**

- Personal familiarity in tone or language
- References to shared experiences, meetings, or conversations
- Inside jokes or personal nicknames
- Mentions of non-work related interactions
- Direct personal questions or congratulations
- Collaborative language suggesting ongoing relationship

**Weak Evidence (suggests they might NOT know each other):**

- Generic professional comments ("Great post!", "Thanks for sharing")
- Purely transactional or informational exchanges
- Formal, distant tone
- No personalization or specific references

Be objective and evidence-based. Professional courtesy does NOT equal personal connection.

PS: You are currently working in an automated system and cannot ask any questions or have back and forth with a user.
