#!/usr/bin/env python3
# /// script
# dependencies = [
#   "openai>=1.0.0",
#   "pydantic>=2.0.0",
# ]
# ///

import argparse
import json
import os
from pathlib import Path
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, field_validator, model_validator
from openai import OpenAI


# Schema definitions
class ActionItem(BaseModel):
    action_item: str
    deadline: Optional[str] = None

    @field_validator('deadline')
    @classmethod
    def validate_iso_format(cls, v):
        if v is None:
            return v
        # Validate ISO 8601 format (supports both date-only and datetime)
        try:
            datetime.fromisoformat(v)
        except ValueError:
            raise ValueError(f"Deadline must be in ISO 8601 format (e.g., '2025-12-20' or '2025-12-20T10:00:00'), got: {v}")
        return v


class MeetingOutput(BaseModel):
    action_items: List[ActionItem]


# Meeting serialization
def serialize_meeting(meeting_data: dict) -> str:
    """Serialize meeting data into a formatted string."""
    raw_data = meeting_data.get("raw_data", {})

    title = meeting_data.get("title", "Untitled Meeting")
    room_name = raw_data.get("room_name", "Unknown Room")
    transcript = raw_data.get("transcript", "")

    # Extract meeting date in ISO format
    meeting_date = meeting_data.get("timestamp") or raw_data.get("created_at", "Unknown Date")

    # Extract summaries if they exist
    short_summary = raw_data.get("short_summary", "No short summary available")
    long_summary = raw_data.get("long_summary", "No long summary available")

    serialized = f"""Title: {title}

Date: {meeting_date}

Room: {room_name}

Short Summary:
{short_summary}

Long Summary:
{long_summary}

Transcript:
{transcript}
"""
    return serialized


def construct_prompt(serialized_meeting: str) -> str:
    """Construct the LLM prompt for extracting action items."""
    prompt = f"""You are analyzing a meeting transcript to extract action items for a specific person named "Michal".

Please carefully read the following meeting and identify ALL action items that are assigned to, mentioned for, or involve Michal (also check for variations like "michal", "Michael", "Michał").

{serialized_meeting}

Extract all action items with the following information:
- action_item: A clear description of what Michal needs to do
- deadline: Any mentioned deadline in ISO 8601 format (e.g., "2025-12-20" or "2025-12-20T10:00:00"), or null if not specified

Be conservative. Only create an action item if you're sure it stems from the conversation and is clearly assigned to or involves Michal. Include all commitments, tasks, and follow-ups for Michal that are explicitly mentioned in the meeting.

You must respond with ONLY valid JSON in this exact format, no markdown, no explanation:
{{
  "action_items": [
    {{"action_item": "Description of task for Michal", "deadline": null}},
    {{"action_item": "Another task with date", "deadline": "2025-12-20"}},
    {{"action_item": "Task with datetime", "deadline": "2025-12-20T10:00:00"}}
  ]
}}"""

    return prompt


def extract_action_items(client: OpenAI, meeting_data: dict, model: str = "gpt-4o-mini") -> MeetingOutput:
    """Extract action items from meeting data using LLM with structured output."""
    serialized = serialize_meeting(meeting_data)
    prompt = construct_prompt(serialized)

    completion = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are a helpful assistant that extracts action items from meeting transcripts. You always respond with valid JSON."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.0,
    )

    content = completion.choices[0].message.content

    # Clean up potential markdown formatting
    if content.startswith("```json"):
        content = content.split("```json")[1]
    if content.startswith("```"):
        content = content.split("```")[1]
    if content.endswith("```"):
        content = content.rsplit("```", 1)[0]

    content = content.strip()

    # Parse JSON and validate with Pydantic
    data = json.loads(content)
    return MeetingOutput.model_validate(data)


def process_meeting_file(client: OpenAI, input_path: Path, output_path: Path, model: str = "gpt-4o-mini"):
    """Process a single meeting JSON file and save the extracted action items."""
    print(f"Processing {input_path.name}...")

    # Read input file
    with open(input_path, 'r') as f:
        meeting_data = json.load(f)

    # Extract action items
    result = extract_action_items(client, meeting_data, model)

    # Save output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(result.model_dump(), f, indent=2)

    print(f"  ✓ Saved to {output_path.name}")
    print(f"  Found {len(result.action_items)} action items for Michal")


def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Extract action items from meeting transcripts")
    parser.add_argument(
        "--file",
        type=str,
        help="Specific JSON file to process (e.g., '1.json' or 'input/1.json'). If not specified, all files in input/ will be processed."
    )
    args = parser.parse_args()

    # Get environment variables
    api_base = os.environ.get("LLM_API_BASE")
    api_key = os.environ.get("LLM_API_KEY")
    api_model = os.environ.get("LLM_MODEL_NAME")

    if not api_key:
        raise ValueError("LLM_API_KEY environment variable is required")

    # Initialize OpenAI client
    client_kwargs = {"api_key": api_key}
    if api_base:
        client_kwargs["base_url"] = api_base

    client = OpenAI(**client_kwargs)

    # Set up paths
    script_dir = Path(__file__).parent
    input_dir = script_dir / "input"
    output_dir = script_dir / "ground_truth"

    # Get model from environment or use default
    model = api_model if api_model else "gpt-4o-mini"

    # Determine which files to process
    if args.file:
        # Process single file
        file_path = Path(args.file)
        if not file_path.is_absolute():
            # Try relative to script directory first
            if file_path.exists():
                input_path = file_path
            # Then try relative to input directory
            elif (input_dir / file_path.name).exists():
                input_path = input_dir / file_path.name
            else:
                print(f"Error: File not found: {args.file}")
                return
        else:
            input_path = file_path

        if not input_path.exists():
            print(f"Error: File not found: {input_path}")
            return

        input_files = [input_path]
    else:
        # Process all JSON files in input directory
        input_files = sorted(input_dir.glob("*.json"))

    if not input_files:
        print("No JSON files found in input directory")
        return

    print(f"Found {len(input_files)} meeting file(s) to process")
    print(f"Using model: {model}")
    print()

    for input_path in input_files:
        output_path = output_dir / input_path.name
        process_meeting_file(client, input_path, output_path, model)
        print()

    print("✅ All meetings processed successfully!")


if __name__ == "__main__":
    main()
