# LLMEval

A tool for evaluating LLM models on coding tasks with automated testing, comparison, and a static website for viewing results.

## Features

- 🚀 **Automated Evaluations**: Run multiple LLM models on defined coding tasks
- 📊 **Static Website**: Beautiful web interface with filtering and sorting
- 🐳 **Docker Deployment**: Containerized setup with automated daily runs
- 🔒 **Secure**: Nginx blocks sensitive workspace directories
- 📈 **Rich Reports**: Detailed session logs and test outputs
- ⏱️ **Scheduled Runs**: Cron-based automation for continuous evaluation

## Requirements

- Python 3.8+
- uv package manager
- [Cubbi](https://github.com/monadical-sas/cubbi) with goose image
- LiteLLM instance with configured models

## Configuration

This project uses **LiteLLM exclusively**. Configure Cubbi with your LiteLLM instance:

```bash
# Set LiteLLM base URL and API key
export LITELLM_BASE_URL=http://localhost:4000
export LITELLM_API_KEY=your_api_key_here

# Configure Cubbi
cubbi config set providers.litellm.base_url $LITELLM_BASE_URL
cubbi config set providers.litellm.api_key $LITELLM_API_KEY
cubbi config models refresh
```

## Usage

```bash
# Install dependencies
uv add rich structlog

# Run evaluation with LiteLLM models
uv run python llmeval.py --model litellm/openrouter/anthropic/claude-sonnet-4 --task path/to/task

# Multiple models
uv run python llmeval.py --model litellm/model1,litellm/model2 --task path/to/task
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

## Static Website

Generate a static website to view and filter evaluation results:

```bash
# Generate website from evaluation results
python llmwebsite.py

# Force regeneration of all pages
python llmwebsite.py --force

# View website
open runs/index.html
```

Features:
- 🎯 **Root Index**: Last 50 runs with filtering by model, date, task
- 📋 **Run Details**: Model rankings, test results, links to outputs
- 🎨 **Monadical Design**: Clean, modern interface inspired by monadical.com
- 🔍 **Client-side Filtering**: Fast, responsive sorting and searching
- 📱 **Responsive**: Works on desktop, tablet, and mobile

## Docker Deployment

Deploy with automated daily evaluations:

```bash
# Setup environment
cp .env.example .env
# Edit .env with your LiteLLM configuration:
#   LITELLM_BASE_URL - URL of your LiteLLM instance
#   LITELLM_API_KEY - API key for authentication
#   EVAL_MODELS - Comma-separated list of models to evaluate
#   EVAL_TASKS - Comma-separated list of tasks to run

# Build and start
docker-compose up -d

# Run evaluation manually
docker-compose exec llmeval bash /app/scripts/generate.sh

# View website
open http://localhost:8080

# View logs
docker-compose logs -f
```

The automated workflow (via cron or manual execution) will:
1. Configure Cubbi with LiteLLM credentials
2. Refresh available models from LiteLLM
3. Build the Cubbi opencode image (cached after first run)
4. Run evaluations for all configured tasks and models
5. Generate static website with results

See [DOCKER_TESTING.md](DOCKER_TESTING.md) for detailed testing guide.

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
