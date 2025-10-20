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

2. **Run Organization**: Results are stored in timestamped directories:
   ```
   runs/run_YYYYMMDD_HHMMSS/
     {normalized-model-name}/
       workspace/          # Working directory (contains task.md, test*.sh, input/)
       session.txt         # Complete LLM interaction log
       test_test*.txt      # Test execution outputs (one per test file)
       result.json         # Execution metadata
     summary.md            # Results table and statistics
     summary-detailed.md   # Full session logs and test outputs
   ```

3. **Concurrent Execution**: Uses asyncio with configurable semaphore to run multiple models in parallel (default: 4 concurrent tasks, configurable via `--concurrent`)

4. **Test Execution**: Multiple test scripts are supported and executed sequentially. Each test file must start with "test" and end with ".sh" (e.g., `test_1_file_exists.sh`, `test_2_valid_json.sh`). Task passes only if ALL tests pass.

### Key Components

- **llmeval.py**: Main orchestrator that manages task execution, parallel processing, and reporting
- **CUBBIX_COMMAND_TEMPLATE**: Defines how Cubbi is invoked with Goose image
- **Result Generation**: Creates both summary tables and detailed markdown reports with full session logs
- **Output Processing**: Strips ANSI escape codes and escapes markdown code blocks to prevent formatting issues in reports

## Common Commands

### Running Evaluations

**Note**: This project uses LiteLLM exclusively. All models must be configured through LiteLLM.

```bash
# Basic evaluation with LiteLLM models
uv run python llmeval.py --model litellm/openrouter/anthropic/claude-sonnet-4 --task tasks/task1_file_list

# Multiple models
uv run python llmeval.py --model litellm/model1,litellm/model2 --task tasks/task1_file_list

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
- Each test produces a separate output file: `test_test*.txt`
- Task fails if ANY test fails (first failure stops execution)
- Test metadata is stored in `result.json` under `test_results` array

### Output Formatting
- ANSI escape codes are stripped from all captured output before writing to markdown
- Triple backticks in output are escaped to prevent markdown formatting issues
- Summary reports are generated in both concise and detailed formats

### Concurrency and Timeouts
- Default: 4 concurrent model evaluations (configurable via `--concurrent`)
- Default timeout: 300 seconds per model (configurable via `--timeout`)
- Tasks that timeout are marked with "❌ Timeout" status
- Rich UI shows live progress updates every 0.5 seconds

## Python Environment

- Uses `uv` for dependency management
- Requires Python 3.13+
- Key dependencies: `rich`, `structlog`, `strip-ansi`
- Virtual environment managed in `.venv/`

## Static Website

### Website Generator (`llmwebsite.py`)
- Generates static HTML from evaluation results
- Root index at `runs/index.html` with last 50 runs
- Per-run detail pages at `runs/run_*/index.html` (cached)
- Monadical-inspired design with filtering and sorting
- Command: `python llmwebsite.py [--force]`

### Static Assets
- `static/style.css` - Monadical design system
- `static/main.js` - Client-side filtering/sorting
- Copied to `runs/static/` during generation

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
