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

# Step 1: Setup podman storage
log "Setting up podman storage..."
mkdir -p /var/lib/containers/storage /run/containers/storage
if podman info > /dev/null 2>&1; then
    log "✓ Podman storage initialized successfully"
else
    log "WARNING: Podman initialization check failed, but continuing..."
fi

# Step 1b: Fix CNI network version to be compatible with firewall plugin
log "Fixing CNI network version compatibility..."
if [ -f /etc/cni/net.d/cubbi-network.conflist ]; then
    # Change cniVersion from 1.0.0 to 0.4.0 for firewall plugin compatibility
    sed -i 's/"cniVersion": "1\.0\.0"/"cniVersion": "0.4.0"/' /etc/cni/net.d/cubbi-network.conflist
    log "✓ CNI network version updated to 0.4.0"
else
    log "INFO: CNI network config not found yet (will be created by podman on first use)"
fi

# Step 1c: Create cubbi network if it doesn't exist
log "Setting up cubbi network..."
if ! podman network exists cubbi-network 2>/dev/null; then
    podman network create cubbi-network > /dev/null 2>&1
    log "✓ Created cubbi-network"
fi

# Fix CNI version after network creation
if [ -f /etc/cni/net.d/cubbi-network.conflist ]; then
    sed -i 's/"cniVersion": "1\.0\.0"/"cniVersion": "0.4.0"/' /etc/cni/net.d/cubbi-network.conflist
    log "✓ CNI network version updated to 0.4.0"
fi

# Step 1d: Enable Podman Docker-compatible socket for cubbi
log "Enabling Podman Docker-compatible socket..."
mkdir -p /var/run
# Start podman socket service in the background
podman system service --time=0 unix:///var/run/docker.sock &
sleep 2  # Give the socket time to start
if [ -S /var/run/docker.sock ]; then
    log "✓ Podman Docker-compatible socket enabled at /var/run/docker.sock"
else
    log "WARNING: Failed to create Docker-compatible socket, but continuing..."
fi

# Step 2: Create necessary directories
log "Creating application directories..."
mkdir -p "${LOGS_DIR}" "${APP_DIR}/runs" "${APP_DIR}/config"

# Step 3: Install cron job for daily evaluation runs
log "Installing cron job (schedule: ${CRON_SCHEDULE})..."

# Create cron job that runs generate.sh
CRON_JOB="${CRON_SCHEDULE} /app/scripts/generate.sh >> ${LOGS_DIR}/cron.log 2>&1"

# Write cron job to crontab
echo "${CRON_JOB}" | crontab -

# Verify cron job was installed
if crontab -l | grep -q "generate.sh"; then
    log "✓ Cron job installed successfully"
    log "  Schedule: ${CRON_SCHEDULE} (CST/CDT)"
    log "  Next run: $(date -d 'next day 12:00' +'%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo 'Check cron logs')"
else
    log "ERROR: Failed to install cron job"
    exit 1
fi

# Step 4: Configure and start nginx
log "Starting nginx web server..."

# Test nginx configuration
if nginx -t > /dev/null 2>&1; then
    log "✓ Nginx configuration is valid"
else
    log "ERROR: Invalid nginx configuration"
    nginx -t
    exit 1
fi

# Start nginx in the background
nginx

# Verify nginx is running
if pgrep -x nginx > /dev/null; then
    log "✓ Nginx started successfully on port 80"
else
    log "ERROR: Failed to start nginx"
    exit 1
fi

# Step 5: Start cron daemon
log "Starting cron daemon..."
cron

# Verify cron is running
if pgrep -x cron > /dev/null; then
    log "✓ Cron daemon started successfully"
else
    log "ERROR: Failed to start cron daemon"
    exit 1
fi

# Step 6: Setup signal handlers for graceful shutdown
shutdown_handler() {
    log "=== Received shutdown signal, stopping services... ==="

    # Stop nginx gracefully
    log "Stopping nginx..."
    nginx -s quit 2>/dev/null || killall nginx 2>/dev/null || true

    # Stop cron
    log "Stopping cron..."
    killall cron 2>/dev/null || true

    # Stop podman socket service
    log "Stopping podman socket service..."
    pkill -f "podman system service" 2>/dev/null || true

    log "✓ Services stopped gracefully"
    exit 0
}

# Trap SIGTERM and SIGINT for graceful shutdown
trap shutdown_handler SIGTERM SIGINT

# Step 7: Display startup information
log "=== LLMEval Container Ready ==="
log "Web server: http://localhost:80"
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

# Step 8: Keep container running by tailing logs
# This blocks the script and keeps the container alive
log "Container running, tailing logs..."
touch "${LOGS_DIR}/cron.log" "${LOGS_DIR}/entrypoint.log"

# Tail multiple log files to keep container running
tail -f "${LOGS_DIR}/cron.log" /var/log/nginx/access.log /var/log/nginx/error.log 2>/dev/null || {
    log "Log files not available yet, using sleep to keep container running"
    sleep infinity
}
