# LLMEval

A tool for evaluating LLM models on coding tasks with automated testing and comparison,
with detailed markdown summary.

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┓
┃ Model                     ┃ Status       ┃ Duration   ┃ Session KB   ┃ Result       ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━┩
│ openrouter/meta-llama/ll… │ Failed       │ 13s        │ 3.8          │ ❌ Test      │
│ openrouter/deepseek/deep… │ Pass         │ 1m 18s     │ 13.6         │ ✔ Pass      │
│ openrouter/cohere/comman… │ Failed       │ 32s        │ 8.9          │ ❌ Test      │
│ openrouter/moonshotai/ki… │ Pass         │ 15s        │ 5.1          │ ✔ Pass      │
│ openrouter/anthropic/cla… │ Pass         │ 2m 41s     │ 33.8         │ ✔ Pass      │
│ openrouter/qwen/qwen3-23… │ Pass         │ 3m 31s     │ 7.6          │ ✔ Pass      │
│ openrouter/mistralai/cod… │ Pass         │ 9s         │ 4.6          │ ✔ Pass      │
│ openrouter/mistralai/dev… │ Pass         │ 6s         │ 2.9          │ ✔ Pass      │
└───────────────────────────┴──────────────┴────────────┴──────────────┴──────────────┘
```

## Requirements

- Python 3.8+
- uv package manager
- cubbix with goose image
- LITELLM_API_KEY environment variable

## Usage

```bash
# Install dependencies
uv add rich structlog

# Basic evaluation with Rich console
uv run python llmeval.py --model gpt-4,claude-3-5-sonnet --task path/to/task

# Verbose mode with detailed logging
uv run python llmeval.py --model gpt-4 --task path/to/task --verbose
```

## Task Structure

```
task_directory/
  task.md           # Prompt for the LLM
  install.sh        # Optional: Setup/installation commands
  test.sh           # Validation script to check task completion
  input/            # Optional: Project files and context
```

## Workflow

1. **Prepare**: Copy task files to workspace
2. **Execute**: Run cubbix with goose in input/ directory
3. **Test**: Validate results with test.sh script
4. **Report**: Generate summary and detailed reports

## Output

Results are saved to `runs/run_YYYYMMDD_HHMMSS/`:

```
runs/run_20250713_123456/
  summary.md              # Overview table and statistics
  summary-detailed.md     # Full session and test outputs
  model-name/
    workspace/          # Working directory
    session.txt         # Complete LLM interaction log
    test.txt            # Test execution output
    result.json         # Metadata and timing
```

### Summary Report (summary.md)
```markdown
# LLMEval Results - 2025-07-13 12:34:56

## Task: hello_world
**Run Path**: `runs/run_20250713_123456`

| Model | Duration | Session Size | Status | Result |
|-------|----------|--------------|--------|--------|
| gpt-4 | 3m 45s | 62.1 KB |  | Pass |
| claude-3-5-sonnet | 4m 32s | 78.5 KB |  | Pass |

## Statistics
- Total models tested: 2
- Successful: 2 (100%)
- Failed execution: 0 (0%)
- Failed tests: 0 (0%)
- Total session data: 140.6 KB
```
