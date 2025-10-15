#!/bin/bash
# init-services.sh - Service initialization script called by systemd
# This replaces the old entrypoint.sh functionality but runs under systemd

set -euo pipefail

# Configuration
APP_DIR="/app"
LOGS_DIR="${APP_DIR}/logs"
CRON_SCHEDULE="${CRON_SCHEDULE:-0 12 * * *}"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | systemd-cat -t llmeval-init
}

log "=== LLMEval Service Initialization Starting ==="

# Step 1: Setup podman storage
log "Setting up podman storage..."
mkdir -p /var/lib/containers/storage /run/containers/storage
if podman info > /dev/null 2>&1; then
    log "✓ Podman storage initialized successfully"
else
    log "WARNING: Podman initialization check failed, but continuing..."
fi

# Step 2: Fix CNI network version compatibility
log "Fixing CNI network version compatibility..."
if [ -f /etc/cni/net.d/cubbi-network.conflist ]; then
    sed -i 's/"cniVersion": "1\.0\.0"/"cniVersion": "0.4.0"/' /etc/cni/net.d/cubbi-network.conflist
    log "✓ CNI network version updated to 0.4.0"
else
    log "INFO: CNI network config not found yet (will be created by podman on first use)"
fi

# Step 3: Create cubbi network
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

# Step 4: Enable Podman Docker-compatible socket
log "Enabling Podman Docker-compatible socket..."
mkdir -p /var/run

# Create a systemd service for podman socket if it doesn't exist
if [ ! -f /etc/systemd/system/podman-socket.service ]; then
    cat > /etc/systemd/system/podman-socket.service <<'EOF'
[Unit]
Description=Podman Docker-compatible API Socket
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/podman system service --time=0 unix:///var/run/docker.sock
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable podman-socket
    systemctl start podman-socket
    log "✓ Podman socket service created and started"
else
    systemctl start podman-socket || log "WARNING: Failed to start podman socket"
fi

sleep 2
if [ -S /var/run/docker.sock ]; then
    log "✓ Podman Docker-compatible socket enabled at /var/run/docker.sock"
else
    log "WARNING: Docker-compatible socket not found"
fi

# Step 5: Create application directories
log "Creating application directories..."
mkdir -p "${LOGS_DIR}" "${APP_DIR}/runs" "${APP_DIR}/config"

# Step 6: Install cron job
log "Installing cron job (schedule: ${CRON_SCHEDULE})..."
CRON_JOB="${CRON_SCHEDULE} /app/scripts/generate.sh >> ${LOGS_DIR}/cron.log 2>&1"
echo "${CRON_JOB}" | crontab -

if crontab -l | grep -q "generate.sh"; then
    log "✓ Cron job installed successfully"
    log "  Schedule: ${CRON_SCHEDULE} (CST/CDT)"
else
    log "ERROR: Failed to install cron job"
    exit 1
fi

log "=== LLMEval Service Initialization Complete ==="
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

exit 0
