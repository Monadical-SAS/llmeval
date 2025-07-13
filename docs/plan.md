# LLMEval Implementation Plan

## Architecture Overview

Single-file CLI tool with parallel execution and real-time status display using Rich Live tables. Built with uv for dependency management.

## Implementation Approach

### Single File Design (`llmeval.py`)
- All functionality in one file for simplicity
- Rich Live table for real-time multi-model status display
- Asyncio for parallel cubbix execution
- Built-in configuration via global variables

## Implementation Strategy

### Phase 1: Setup & Core Structure
1. Initialize uv project and add Rich dependency: `uv add rich`
2. Implement CLI argument parsing
3. Create workspace management functions
4. Add model name normalization (replace `/` with `-`)

### Phase 2: Execution Engine
1. Implement installation phase (run install.sh if exists)
2. Implement cubbix command execution with session capture
3. Add test script execution
4. Error handling and result tracking

### Phase 3: Rich Live Display
1. Create live status table with Rich Live
2. Real-time updates during parallel execution
3. Status tracking (Preparing → Installing → Running → Testing → Complete/Failed)

### Phase 4: Reporting & Polish
1. Result JSON generation
2. HedgeDoc-compatible summary markdown
3. Error handling refinement

## File Structure (Simplified)
```
evals/
├── llmeval.py           # Single-file implementation
├── docs/
│   ├── project-overview.md
│   └── plan.md
├── pyproject.toml       # uv configuration
└── sample_task/         # Example task for testing
    ├── task.md
    ├── install.sh       # Optional installation script
    ├── test.sh
    └── input/
```

## Rich Console Design

### Status Table
```
┌─────────────────────────┬──────────┬──────────┬─────────────┬──────────┐
│ Model                   │ Status   │ Duration │ Session KB  │ Result   │
├─────────────────────────┼──────────┼──────────┼─────────────┼──────────┤
│ gpt-4                   │ Running  │ 2m 15s   │ 45.2        │ -        │
│ claude-3-5-sonnet       │ Testing  │ 4m 32s   │ 78.5        │ -        │
│ openrouter-deepseek-r1  │ Complete │ 3m 45s   │ 62.1        │ ✅ Pass  │
│ gpt-3.5-turbo          │ Failed   │ 1m 20s   │ 12.3        │ ❌ Exec  │
└─────────────────────────┴──────────┴──────────┴─────────────┴──────────┘
```

### Status Legend
- **Preparing**: Setting up workspace
- **Installing**: Running install.sh script (if exists)
- **Running**: Cubbix execution in progress
- **Testing**: Running test.sh script
- **Complete**: All steps finished successfully
- **Failed**: Error during installation, execution, or test

### Result Types
- **✅ Pass**: Test passed
- **❌ Install**: Installation script failed
- **❌ Exec**: Cubbix execution failed
- **❌ Test**: Test script failed

## Configuration Variables (Global)

```python
# Cubbix command template
CUBBIX_COMMAND_TEMPLATE = [
    "cubbix", "-m", "personalcrm", "-i", "goose",
    "-c", "services.openai.url=https://litellm.app.monadical.io",
    "-c", "services.openai.api_key=${LITELLM_API_KEY}",
    "--model", "{model}",
    "--provider", "openai",
    "--no-shell",
    "--run", "goose run -i task.md",
    "."
]

# Directory structure
RUNS_DIR = "runs"
WORKSPACE_SUBDIR = "workspace"
```

## Rich Live Table Implementation

Rich Live tables provide real-time updates with the following approach:

```python
from rich.live import Live
from rich.table import Table

def create_status_table(model_statuses):
    table = Table(title="LLMEval Progress")
    table.add_column("Model", style="cyan")
    table.add_column("Status", style="magenta") 
    table.add_column("Duration", style="yellow")
    table.add_column("Session KB", style="green")
    table.add_column("Result", style="bold")
    
    for model, status in model_statuses.items():
        table.add_row(model, status['status'], status['duration'], 
                     status['session_size'], status['result'])
    return table

# Usage with Live context manager
with Live(create_status_table({}), refresh_per_second=2) as live:
    while models_running:
        live.update(create_status_table(current_statuses))
        await asyncio.sleep(0.5)
```

## Parallel Execution Strategy

1. Use `asyncio` with `subprocess.Popen` for parallel cubbix execution
2. Use `rich.live.Live` for real-time table updates (confirmed working)
3. Thread-safe result collection
4. Graceful handling of process completion
5. Installation phase before cubbix execution

## Error Handling

### Execution Failures
- Capture exit codes
- Save partial session.txt if available
- Mark as "Exec" failure type
- Continue with other models

### Test Failures
- Always run test.sh if cubbix succeeded
- Capture test output
- Mark as "Test" failure type
- Include in final results

## Summary Generation

### HedgeDoc-Compatible Markdown
```markdown
# LLMEval Results - {timestamp}

## Task: {task_name}

| Model | Duration | Session Size | Status | Result |
|-------|----------|--------------|--------|--------|
| gpt-4 | 3m 45s | 62.1 KB | ✅ | Pass |
| claude-3-5-sonnet | 4m 32s | 78.5 KB | ❌ | Test Failed |

## Statistics
- Total models tested: 4
- Successful: 2 (50%)
- Failed execution: 1 (25%)
- Failed tests: 1 (25%)
- Average duration: 3m 23s
- Total session data: 201.4 KB
```

## Dependencies & Setup

### uv Package Management
```bash
uv add rich
```

### Standard Library Usage
- `asyncio`: Parallel execution
- `subprocess`: Process management
- `json`: Result metadata
- `pathlib`: File operations
- `datetime`: Timestamps
- `argparse`: CLI interface

### System Requirements
- `cubbix` command available in PATH
- `LITELLM_API_KEY` environment variable
- Bash shell for install.sh and test.sh execution

### Running the Tool
```bash
uv run python llmeval.py --model gpt-4,claude-3-5-sonnet --task path/to/task
```

## Testing Strategy

### Sample Task Structure
```
sample_task/
├── task.md          
├── install.sh       
├── test.sh          
└── input/           
    └── .gitkeep
```

## Execution Flow per Model
1. **Prepare**: Create workspace, copy task.md and input/
2. **Install**: Run install.sh if it exists (in workspace)
3. **Execute**: Run cubbix with goose
4. **Test**: Copy and run test.sh in workspace
5. **Collect**: Save results, generate metadata

## Code Quality

### Style Requirements
- **No comments in code**: Keep code self-documenting with clear variable/function names
- **Linting**: Use `uvx ruff check llmeval.py` to validate code quality
- **Format**: Follow PEP 8 standards automatically enforced by ruff

This plan prioritizes simplicity with a single-file implementation while providing rich visual feedback through Live tables.