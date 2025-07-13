# LLMEval Project Overview

## Purpose
LLMEval is a tool for evaluating how different LLM models perform tasks according to multiple criteria. It provides automated testing and comparison across multiple models with structured output and reporting.

## Task Structure
Each task is defined as a directory containing:
- `task.md`: The prompt file passed to the LLM
- `install.sh` (optional): Installation script run before goose execution
- `test.sh`: Validation script that determines task success/failure
- `input/` (optional): Directory serving as the root workspace for the LLM

## Workflow

### 1. Invocation
```bash
llmeval --model x,y,z --task path/to/task
```

### 2. Run Directory Creation
- Creates `runs/run_{isoformatdate}/` folder
- Organizes results by timestamp for historical tracking

### 3. Model Execution (Parallel)
For each specified model:
- Creates workspace: `runs/run_{date}/{normalized_model}/workspace/`
- Model names normalized by replacing `/` with `-` (e.g., `openrouter/deepseek/deepseek-r1-0528` → `openrouter-deepseek-deepseek-r1-0528`)
- Copies `task.md` and `input/` directory to workspace
- **Installation Phase**: Runs `install.sh` if it exists in the workspace
- Executes cubbix command:
  ```bash
  cubbix -m personalcrm -i goose \
    -c services.openai.url=https://litellm.app.monadical.io \
    -c services.openai.api_key=${LITELLM_API_KEY} \
    --model {model} --provider openai --no-shell \
    --run "goose run -i task.md" .
  ```

### 4. Session Capture
- Captures stdout/stderr as `session.txt` in model directory
- Preserves complete interaction log for analysis

### 5. Test Execution
- Copies `test.sh` script to workspace directory after cubbix execution
- Runs `test.sh` script in the workspace directory
- Saves output as `test.txt`
- Determines task success/failure

### 6. Metadata Collection
Generates `result.json` with:
- Execution date/time
- Model name
- Duration
- Command used
- Success/failure status
- Failure type (installation, execution, or test)
- Session size

### 7. Summary Generation
Creates `summary.md` in run folder containing:
- Original task name and description
- Final results for each model (up to 20 models)
- Execution duration
- Success/failure compliance
- Session size comparison
- HedgeDoc-compatible formatting with tables

## Technical Requirements
- Parallel execution of cubbix processes
- Rich console interface for progress tracking
- Hardcoded cubbix command defaults (global variables)
- No timeout for cubbix execution
- No environment files or persistent config initially

## Key Features
- Multi-model comparison
- Automated validation
- Structured result storage
- Historical run tracking
- Rich progress visualization