#!/bin/bash
# generate.sh - Main script for running LLM evaluations and generating static website
# This script is executed daily by cron to perform automated evaluations
# Assumes it is run from the application directory (/app)

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Configuration - assume current directory is app directory
LOGS_DIR="logs"

# Create logs directory if it doesn't exist
mkdir -p "${LOGS_DIR}"

# Generate timestamp for log file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOGS_DIR}/generate_${TIMESTAMP}.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

log "=== Starting LLMEval generation workflow ==="
log "Working directory: $(pwd)"

# Verify Docker is accessible
if ! docker info > /dev/null 2>&1; then
    log "ERROR: Docker is not accessible. Check that DOCKER_HOST is configured correctly."
    exit 1
fi
log "✓ Docker is accessible"

# Step 1: Configure cubbi with LiteLLM
log "Configuring cubbi with LiteLLM..."

# Check for required environment variables
if [[ -z "${LITELLM_BASE_URL:-}" ]]; then
    log "ERROR: LITELLM_BASE_URL environment variable not set"
    exit 1
fi

if [[ -z "${LITELLM_API_KEY:-}" ]]; then
    log "ERROR: LITELLM_API_KEY environment variable not set"
    exit 1
fi

# Configure LiteLLM provider
if cubbi config set providers.litellm.type openai >> "${LOG_FILE}" 2>&1; then
    log "✓ Set LiteLLM type: openai"
else
    log "ERROR: Failed to set LiteLLM type"
    exit 1
fi

if cubbi config set providers.litellm.base_url "${LITELLM_BASE_URL}" >> "${LOG_FILE}" 2>&1; then
    log "✓ Set LiteLLM base URL: ${LITELLM_BASE_URL}"
else
    log "ERROR: Failed to set LiteLLM base URL"
    exit 1
fi

if cubbi config set providers.litellm.api_key "${LITELLM_API_KEY}" >> "${LOG_FILE}" 2>&1; then
    log "✓ Set LiteLLM API key"
else
    log "ERROR: Failed to set LiteLLM API key"
    exit 1
fi

# Refresh models from LiteLLM
if cubbi config models refresh >> "${LOG_FILE}" 2>&1; then
    log "✓ Refreshed models from LiteLLM"
else
    log "ERROR: Failed to refresh models"
    exit 1
fi

# Set default image to opencode
if cubbi config set defaults.image opencode >> "${LOG_FILE}" 2>&1; then
    log "✓ Set default image to opencode"
else
    log "ERROR: Failed to set default image"
    exit 1
fi


# Step 2: Build cubbi opencode image
# This is cached after the first build, so subsequent runs are fast
log "Building cubbi opencode image..."
if cubbi image build opencode >> "${LOG_FILE}" 2>&1; then
    log "✓ Cubbi opencode image built successfully"
else
    log "ERROR: Failed to build cubbi opencode image"
    exit 1
fi

# Step 3: Read models from environment variable
if [[ -z "${EVAL_MODELS:-}" ]]; then
    log "ERROR: EVAL_MODELS environment variable not set"
    exit 1
fi

MODEL_LIST="${EVAL_MODELS}"
log "Models: ${MODEL_LIST}"

# Step 3.5: Read concurrency setting from environment variable (default: 4)
CONCURRENT="${CONCURRENT:-4}"
log "Concurrency: ${CONCURRENT}"

# Step 4: Read tasks from environment variable (optional - auto-discovers if not set)
if [[ -z "${EVAL_TASKS:-}" ]]; then
    log "EVAL_TASKS not set - using auto-discovery (all tasks in tasks/ directory)"
    # Run llmeval.py once with auto-discovery (no --task argument)
    log "Running evaluation for all tasks with auto-discovery..."
    if uv run python llmeval.py --model "${MODEL_LIST}" --concurrent "${CONCURRENT}" >> "${LOG_FILE}" 2>&1; then
        log "✓ Successfully completed evaluation for all tasks"
        FAILED_TASKS=0
        TOTAL_TASKS=1
    else
        log "ERROR: Evaluation failed for auto-discovered tasks"
        FAILED_TASKS=1
        TOTAL_TASKS=1
    fi
else
    # Split tasks by comma into array
    IFS=',' read -ra TASKS <<< "${EVAL_TASKS}"
    log "Loaded ${#TASKS[@]} tasks from EVAL_TASKS"

    # Track overall success/failure
    FAILED_TASKS=0
    TOTAL_TASKS=${#TASKS[@]}

    # Step 5: Run evaluations for each task
    for TASK in "${TASKS[@]}"; do
        log "--- Processing task: ${TASK} ---"

        # Verify task directory exists
        if [[ ! -d "${TASK}" ]]; then
            log "WARNING: Task directory not found: ${TASK}, skipping..."
            ((FAILED_TASKS++))
            continue
        fi

        # Run llmeval.py for this task with all configured models
        log "Running evaluation for task: ${TASK}"
        if uv run python llmeval.py --model "${MODEL_LIST}" --task "${TASK}" --concurrent "${CONCURRENT}" >> "${LOG_FILE}" 2>&1; then
            log "✓ Successfully completed evaluation for ${TASK}"
        else
            log "ERROR: Evaluation failed for task: ${TASK}"
            ((FAILED_TASKS++))
            # Continue with next task instead of exiting
            continue
        fi
    done

    # Report task completion status
    log "=== Task Completion Summary ==="
    log "Total tasks: ${TOTAL_TASKS}"
    log "Successful: $((TOTAL_TASKS - FAILED_TASKS))"
    log "Failed: ${FAILED_TASKS}"
fi

# Step 6: Generate static website from evaluation results
log "Generating static website..."
if uv run python llmwebsite.py >> "${LOG_FILE}" 2>&1; then
    log "✓ Static website generated successfully"
else
    log "ERROR: Failed to generate static website"
    exit 1
fi

# Final summary
log "=== LLMEval generation workflow completed ==="
log "Log file: ${LOG_FILE}"

# Exit with error code if any tasks failed
if [[ ${FAILED_TASKS} -gt 0 ]]; then
    log "WARNING: ${FAILED_TASKS} task(s) failed during evaluation"
    exit 1
fi

log "✓ All tasks completed successfully"
exit 0
