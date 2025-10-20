#!/bin/bash
# entrypoint.sh - Container startup script for LLMEval service
# This script initializes all required services and keeps the container running

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Configuration
APP_DIR="/app"
LOGS_DIR="${APP_DIR}/logs"
CRON_SCHEDULE="${CRON_SCHEDULE:-0 12 * * *}"  # Default: 12:00 PM CST daily

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "=== LLMEval Container Starting ==="

# Step 1: Create necessary directories
log "Creating application directories..."
mkdir -p "${LOGS_DIR}" "${APP_DIR}/runs" "${APP_DIR}/config"

# Step 2: Install cron job for daily evaluation runs
log "Installing cron job (schedule: ${CRON_SCHEDULE})..."

# Create cron job that runs generate.sh
CRON_JOB="${CRON_SCHEDULE} /app/scripts/generate.sh >> ${LOGS_DIR}/cron.log 2>&1"

# Write cron job to crontab
echo "${CRON_JOB}" | crontab -

# Verify cron job was installed
if crontab -l | grep -q "generate.sh"; then
    log "✓ Cron job installed successfully"
    log "  Schedule: ${CRON_SCHEDULE} (CST/CDT)"
else
    log "ERROR: Failed to install cron job"
    exit 1
fi

# Step 3: Start cron daemon
log "Starting cron daemon..."
cron

# Verify cron is running
if pgrep -x cron > /dev/null; then
    log "✓ Cron daemon started successfully"
else
    log "ERROR: Failed to start cron daemon"
    exit 1
fi

# Step 4: Setup signal handlers for graceful shutdown
shutdown_handler() {
    log "=== Received shutdown signal, stopping services... ==="

    # Stop cron
    log "Stopping cron..."
    killall cron 2>/dev/null || true

    log "✓ Services stopped gracefully"
    exit 0
}

# Trap SIGTERM and SIGINT for graceful shutdown
trap shutdown_handler SIGTERM SIGINT

# Step 5: Display startup information
log "=== LLMEval Container Ready ==="
log "Web server: Served by Caddy (separate container)"
log "Application directory: ${APP_DIR}"
log "Logs directory: ${LOGS_DIR}"
log "Cron schedule: ${CRON_SCHEDULE}"
log ""
log "To manually run evaluation:"
log "  docker-compose exec llmeval /app/scripts/generate.sh"
log ""
log "To view cron logs:"
log "  docker-compose exec llmeval tail -f ${LOGS_DIR}/cron.log"
log ""

# Step 6: Keep container running by tailing logs
# This blocks the script and keeps the container alive
log "Container running, tailing logs..."
touch "${LOGS_DIR}/cron.log"

# Tail cron log to keep container running
tail -f "${LOGS_DIR}/cron.log" 2>/dev/null || {
    log "Log files not available yet, using sleep to keep container running"
    sleep infinity
}
