# LLMEval

A tool for evaluating LLM models on coding tasks with automated testing and comparison,
with detailed markdown summary.

## Requirements

- Python 3.8+
- uv package manager
- [Cubbi](https://github.com/monadical-sas/cubbi) with goose image, with at least one provider configured

## Usage

```bash
# Install dependencies
uv add rich structlog

# Evaluation with openai/anthropic provider
uv run python llmeval.py --model openai/gpt-4,anthropic/claude-3-5-sonnet --task path/to/task

# Evaluation with litellm provider (configured in cubbi), and using openrouter
uv run python llmeval.py --model litellm/openrouter/moonshotai/kimi-k2 --task path/to/task
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
# LLMEval Results - 2025-08-20 10:31:14

## Task: task1_file_list
**Run Path**: `runs/run_20250820_102336`

| Model | Duration | Session Size | Status | Result | Tests Passed |
|-------|----------|--------------|--------|--------|--------------|
| litellm/openrouter/openai/gpt-4 | 28s | 8.2 KB | ✅ | Pass | 4/4 |
| litellm/openrouter/anthropic/claude-sonnet-4 | 26s | 9.9 KB | ✅ | Pass | 4/4 |
| litellm/openrouter/qwen/qwen3-30b-a3b-instruct-2507 | 5s | 4.3 KB | ❌ | test_1_file_exists.sh | 0/1 |
| litellm/openrouter/qwen/qwen3-235b-a22b-thinking-2507 | 5m 0s | 0.0 KB | ❌ | Timeout | N/A |
| litellm/openrouter/qwen/qwen3-coder | 51s | 12.2 KB | ✅ | Pass | 4/4 |
| litellm/openrouter/z-ai/glm-4.5-air | 38s | 12.2 KB | ✅ | Pass | 4/4 |
| litellm/openrouter/z-ai/glm-4.5 | 23s | 7.9 KB | ✅ | Pass | 4/4 |
| litellm/openrouter/z-ai/glm-4-32b | 14s | 6.9 KB | ❌ | test_2_valid_json.sh | 1/2 |
| litellm/openrouter/meta-llama/llama-4-scout | 7s | 9.0 KB | ❌ | test_2_valid_json.sh | 1/2 |
| litellm/openrouter/microsoft/phi-4 | 5s | 4.2 KB | ❌ | test_1_file_exists.sh | 0/1 |
| litellm/openrouter/deepseek/deepseek-r1-0528 | 5m 0s | 0.0 KB | ❌ | Timeout | N/A |
| litellm/openrouter/deepseek/deepseek-chat-v3-0324 | 55s | 11.3 KB | ✅ | Pass | 4/4 |
| litellm/openrouter/mistralai/mistral-medium-3.1 | 7s | 5.1 KB | ❌ | test_1_file_exists.sh | 0/1 |
| litellm/openrouter/ai21/jamba-mini-1.7 | 7s | 3.2 KB | ❌ | test_1_file_exists.sh | 0/1 |
| litellm/openrouter/ai21/jamba-large-1.7 | 8s | 3.4 KB | ❌ | test_2_valid_json.sh | 1/2 |
| litellm/openrouter/openai/gpt-oss-120b | 11s | 7.3 KB | ✅ | Pass | 4/4 |
| litellm/openrouter/openai/gpt-oss-20b | 37s | 8.4 KB | ✅ | Pass | 4/4 |
| litellm/openrouter/mistralai/codestral-2508 | 37s | 5.0 KB | ❌ | test_1_file_exists.sh | 0/1 |
| litellm/openrouter/moonshotai/kimi-k2 | 30s | 9.3 KB | ✅ | Pass | 4/4 |
| litellm/openrouter/minimax/minimax-m1 | 5m 0s | 0.0 KB | ❌ | Timeout | N/A |
| litellm/openrouter/qwen/qwen3-14b | 1m 29s | 4.9 KB | ✅ | Pass | 4/4 |

## Statistics
- Total models tested: 21
- Successful: 10 (48%)
- Failed execution: 0 (0%)
- Failed tests: 0 (0%)
- Failed errors: 0 (0%)
- Total session data: 132.7 KB
```
