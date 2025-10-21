# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LLMEval is an automated evaluation framework for testing and comparing LLM coding capabilities. It runs LLM models through defined coding tasks using Cubbi/Goose and validates results with automated test scripts, generating detailed comparison reports.

## Core Architecture

### Execution Flow
1. **Task Definition**: Each task is a directory containing:
   - `task.md` - The prompt given to the LLM
   - `test*.sh` - One or more test scripts that validate task completion (named `test_*.sh`, executed in sorted order)
   - `install.sh` (optional) - Setup commands run before task execution
   - `input/` (optional) - Working directory and initial files for the LLM

2. **Run Organization**: Results are stored in timestamped directories with a nested task/model structure:
   ```
   runs/run_YYYYMMDD_HHMMSS/
     run_metadata.json     # Run-level metadata (timestamp, tasks, models)
     {normalized-task-name}/
       {normalized-model-name}/
         workspace/        # Working directory (contains task.md, test*.sh, input/)
         session.txt       # Complete LLM interaction log
         test_test*.txt    # Test execution outputs (one per test file)
         result.json       # Execution metadata
       summary.md          # Task-level results table
       summary-detailed.md # Full session logs and test outputs for this task
   ```

   **Note**: For single-task runs, the structure is the same but contains only one task directory.

3. **Concurrent Execution**: Uses asyncio with configurable semaphore to run multiple model×task combinations in parallel (default: 10 concurrent executions, configurable via `--concurrent`). All combinations are flattened and executed concurrently up to the semaphore limit.

4. **Test Execution**: Multiple test scripts are supported and ALL tests are executed even if some fail. Each test file must start with "test" and end with ".sh" (e.g., `test_1_file_exists.sh`, `test_2_valid_json.sh`). All test results are collected and reported. Task passes only if ALL tests pass, but all tests are always run to provide complete diagnostics.

### Key Components

- **llmeval.py**: Main orchestrator that manages task execution, parallel processing, and reporting
- **CUBBIX_COMMAND_TEMPLATE**: Defines how Cubbi is invoked with Goose image
- **Result Generation**: Creates both summary tables and detailed markdown reports with full session logs
- **Output Processing**: Strips ANSI escape codes and escapes markdown code blocks to prevent formatting issues in reports

## Common Commands

### Running Evaluations

**Note**: This project uses LiteLLM exclusively. All models must be configured through LiteLLM.

```bash
# Run all tasks (auto-discovery from tasks/ directory)
uv run python llmeval.py --model litellm/openrouter/anthropic/claude-sonnet-4

# Basic evaluation with single task and single model
uv run python llmeval.py --model litellm/openrouter/anthropic/claude-sonnet-4 --task tasks/task1_file_list

# Multiple models, all tasks
uv run python llmeval.py --model litellm/model1,litellm/model2

# Multiple models, single task
uv run python llmeval.py --model litellm/model1,litellm/model2 --task tasks/task1_file_list

# Multiple tasks, single model
uv run python llmeval.py --model litellm/openrouter/anthropic/claude-sonnet-4 --task tasks/task1,tasks/task2

# Multiple models and multiple tasks (cross-product evaluation)
uv run python llmeval.py --model litellm/model1,litellm/model2 --task tasks/task1,tasks/task2

# With custom timeout and concurrency
uv run python llmeval.py --model litellm/model --task <path> --timeout 600 --concurrent 8

# Verbose mode (structlog instead of Rich UI)
uv run python llmeval.py --model litellm/model --task <path> --verbose
```

### LiteLLM Configuration

Before running evaluations, configure Cubbi with your LiteLLM instance:

```bash
# Set LiteLLM base URL
cubbi config set providers.litellm.base_url $LITELLM_BASE_URL

# Set LiteLLM API key
cubbi config set providers.litellm.api_key $LITELLM_API_KEY

# Refresh available models
cubbi config models refresh
```

### Development

```bash
# Install dependencies
uv add <package>

# Run with verbose logging
uv run python llmeval.py --verbose --model <model> --task <path>
```

### Creating New Tasks

1. Create a new directory under `tasks/`
2. Add `task.md` with the LLM prompt
3. Add one or more test scripts (e.g., `test_1_basic.sh`, `test_2_advanced.sh`)
4. Optionally add `install.sh` for setup and `input/` directory for initial files
5. Ensure test scripts exit with code 0 for success, non-zero for failure

## Important Implementation Details

### Model Name Normalization
- Model names are normalized by replacing `/` with `-`
- Example: `openrouter/deepseek/deepseek-r1-0528` → `openrouter-deepseek-deepseek-r1-0528`
- This affects directory naming in `runs/` folder

### Cubbix Integration
- Uses `cubbix -i goose` with the specified model
- Executes `install.sh` if present, then runs `goose run -i ../task.md` in the input directory
- Session output captured to `session.txt` for analysis

### Test Scripts
- Tests are identified by the pattern `test*.sh` in the task directory
- All tests are copied to workspace and executed in sorted order
- **All tests are always executed** even if some fail, providing complete diagnostic information
- Each test produces a separate output file: `test_test*.txt`
- Task passes only if ALL tests pass, but execution continues through all tests
- All test results (passed and failed) are stored in `result.json` under `test_results` array

### Output Formatting
- ANSI escape codes are stripped from all captured output before writing to markdown
- Triple backticks in output are escaped to prevent markdown formatting issues
- Summary reports are generated in both concise and detailed formats

### Concurrency and Timeouts
- Default: 10 concurrent model×task executions (configurable via `--concurrent`)
- All model×task combinations are flattened and executed concurrently up to the semaphore limit
- For example: 3 models × 2 tasks = 6 concurrent executions (all run in parallel if limit allows)
- Default timeout: 300 seconds per model×task execution (configurable via `--timeout`)
- Tasks that timeout are marked with "❌ Timeout" status
- Rich UI shows live progress updates every 0.5 seconds with task context

## Python Environment

- Uses `uv` for dependency management
- Requires Python 3.13+
- Key dependencies: `rich`, `structlog`, `strip-ansi`
- Virtual environment managed in `.venv/`

## Static Website

### Website Generator (`llmwebsite.py`)
- Generates static HTML from evaluation results with a 3-level hierarchy
- **Root index** (`runs/index.html`): Shows last 50 runs with one row per run and one column per task
- **Run overview** (`runs/run_*/index.html`): For multi-task runs, displays a model×task grid showing pass/fail status
- **Task detail** (`runs/run_*/task_*/index.html`): Shows test-level results for each task with session logs and test outputs
- Monadical-inspired design with filtering and sorting
- Command: `python llmwebsite.py [--force]`

**Note**: For single-task runs, the run overview page is skipped and links go directly to the task detail page.

### Static Assets
- `static/style.css` - Monadical design system
- `static/main.js` - Client-side filtering/sorting
- Copied to `runs/static/` during generation

## Migration Notes

### Breaking Change: Multi-Task Directory Structure

**Version**: 2025-10-20 - Added multi-task support with new directory structure

**What Changed**:
- Old structure: `runs/run_*/model/workspace/`
- New structure: `runs/run_*/task/model/workspace/`

**Impact**:
- Runs created before this change are incompatible with the new website generator
- Old runs will not appear in the root index or be accessible via the web interface
- The evaluation framework (`llmeval.py`) only creates runs in the new format

**Recommended Actions**:
1. **Backup existing runs**: Move or copy your `runs/` directory before upgrading
   ```bash
   cp -r runs runs.backup.$(date +%Y%m%d)
   ```
2. **Separate old and new runs**: Keep old runs in a separate directory for reference
3. **Re-run evaluations**: If you need old results in the new format, re-run the evaluations

**Why This Change**:
- Enables running multiple tasks in a single evaluation run
- Provides better organization for cross-product model×task evaluations
- Allows for more comprehensive comparison reports across tasks

## Deployment

### Local Execution with Caddy Web Server

The evaluation framework runs locally on your machine, while Caddy serves the static website from a Docker container.

```bash
# Start Caddy web server
docker-compose up -d

# Run evaluation locally (after configuring LiteLLM)
uv run python llmeval.py --model litellm/openrouter/anthropic/claude-sonnet-4 --task tasks/task1_file_list

# Generate static website
uv run python llmwebsite.py

# Access website
open https://eval.monadical.io
# or locally: http://localhost

# Stop Caddy
docker-compose down
```

### Configuration
- `.env` - Environment variables (copy from `.env.example`). Required variables:
  - `LITELLM_BASE_URL` - URL of your LiteLLM instance
  - `LITELLM_API_KEY` - API key for LiteLLM authentication
  - `EVAL_MODELS` - Comma-separated list of models to evaluate (for automated scripts)
  - `EVAL_TASKS` - Comma-separated list of task paths to run (for automated scripts)

### Automated Runs with Cron

For automated daily runs, set up a cron job on your local machine or server:

```bash
# Edit crontab
crontab -e

# Add daily run at 12:00 CST (example)
0 12 * * * cd /path/to/evals && /path/to/scripts/generate.sh >> logs/cron.log 2>&1
```

The `scripts/generate.sh` script:
1. Configures Cubbi with LiteLLM credentials
2. Refreshes available models from LiteLLM
3. Builds cubbi opencode image (cached)
4. Runs llmeval.py for each task
5. Generates static website

Logs are stored in `logs/`

### Web Server (Caddy)

- Caddy automatically handles HTTPS via Let's Encrypt for `eval.monadical.io`
- Serves static files from `runs/` directory
- Blocks access to `workspace/` directories for security
- Configured via `Caddyfile`

### Security
- Caddy blocks access to `workspace/` directories
- API keys via environment variables only
- Evaluations run in isolated Docker containers via Cubbi
