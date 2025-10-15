# Dockerfile for LLMEval automated evaluation and static website hosting
# Base: Ubuntu 22.04 LTS for stability and wide package support
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to Central Time (CST/CDT)
ENV TZ=America/Chicago

# Install system dependencies
# - systemd: Init system for proper cgroup delegation (PID 1)
# - curl, ca-certificates, gnupg: For downloading packages and verifying signatures
# - python3.13, python3-pip: Python runtime and package manager
# - podman: Container runtime for cubbi to execute LLM evaluation environments
# - cron: For scheduled evaluation runs
# - nginx: Web server to serve static evaluation results
# - git: For potential repository updates and version control
# - tzdata: Timezone data for correct scheduling
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    curl \
    ca-certificates \
    gnupg \
    software-properties-common \
    cron \
    nginx \
    git \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Configure systemd for container use
# Remove unnecessary systemd services and targets
RUN cd /lib/systemd/system/sysinit.target.wants/ && \
    ls | grep -v systemd-tmpfiles-setup | xargs rm -f && \
    rm -f /lib/systemd/system/multi-user.target.wants/* \
          /etc/systemd/system/*.wants/* \
          /lib/systemd/system/local-fs.target.wants/* \
          /lib/systemd/system/sockets.target.wants/*udev* \
          /lib/systemd/system/sockets.target.wants/*initctl* \
          /lib/systemd/system/basic.target.wants/* \
          /lib/systemd/system/anaconda.target.wants/* \
          /lib/systemd/system/plymouth* \
          /lib/systemd/system/systemd-update-utmp*

# Install Python 3.13 from deadsnakes PPA
# Ubuntu 22.04 ships with older Python, so we need to add the PPA
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y \
    python3.13 \
    python3.13-venv \
    python3.13-dev \
    && rm -rf /var/lib/apt/lists/*

# Install uv (modern Python package installer and environment manager)
# uv is significantly faster than pip and handles dependency resolution better
# The install script places uv in /root/.local/bin
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Install Podman for rootless container execution
# Cubbi uses podman to create isolated environments for LLM evaluations
RUN apt-get update && apt-get install -y \
    podman \
    fuse-overlayfs \
    slirp4netns \
    uidmap \
    && rm -rf /var/lib/apt/lists/*

# Configure Podman to work inside Docker container
RUN mkdir -p /etc/containers && \
    cat > /etc/containers/storage.conf <<'EOF'
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"
EOF

RUN cat > /etc/containers/containers.conf <<'EOF'
[engine]
cgroup_manager = "cgroupfs"
events_logger = "file"

[containers]
userns = "host"
ipcns = "host"
netns = "host"
cgroupns = "host"
pids_limit = 0
default_sysctls = []
seccomp_profile = "/usr/share/containers/seccomp.json"
apparmor_profile = "unconfined"
EOF

# Set environment variables for buildah
ENV BUILDAH_ISOLATION=chroot

# Also add to profile so it persists in interactive shells
RUN echo 'export BUILDAH_ISOLATION=chroot' >> /etc/profile && \
    echo 'export BUILDAH_ISOLATION=chroot' >> /etc/bash.bashrc

# Create a wrapper script for podman that adds security options
# XXX when trying to build opencode (cubbi image build opencode),
# XXX `npm i -g yarn` will fail with:
# STEP 10/27: RUN npm i -g yarn
# node: ../deps/uv/src/unix/core.c:644: uv__close: Assertion `fd > STDERR_FILENO' failed.
# Aborted (core dumped)
# subprocess exited with status 134
# subprocess exited with status 134
# The solution given by calude is using --security-opt seccomp=unconfined.
RUN mv /usr/bin/podman /usr/bin/podman-original && \
    cat > /usr/bin/podman <<'EOF'
#!/bin/bash
if [ "$1" = "build" ]; then
    exec /usr/bin/podman-original build --isolation=chroot --security-opt seccomp=unconfined "${@:2}"
else
    exec /usr/bin/podman-original "$@"
fi
EOF
RUN chmod +x /usr/bin/podman

# Create docker->podman symlink for tools that expect 'docker' command
RUN ln -s /usr/bin/podman /usr/local/bin/docker

# Install cubbi CLI tool for LLM code evaluation
# Cubbi provides sandboxed environments for testing LLM coding capabilities
# Install from source using git checkout and uv tool install
RUN git clone https://github.com/monadical-sas/cubbi.git /tmp/cubbi && \
    cd /tmp/cubbi && \
    uv tool install . && \
    cd / && \
    rm -rf /tmp/cubbi

# Verify cubbi installation (binary location check only, --version requires Docker)
RUN which cubbi

# Set working directory for the application
WORKDIR /app

# Copy application code
# This includes llmeval.py, llmwebsite.py, tasks/, and configuration files
COPY . /app/

# Create necessary directories with proper permissions
# - runs/: Stores evaluation results and generated website
# - logs/: Stores cron job and script execution logs
# - config/: Stores configuration files (models.txt, tasks.txt)
RUN mkdir -p /app/runs /app/logs /app/config /app/static /app/scripts && \
    chmod -R 755 /app

# Install Python dependencies using uv
# Use --system to install packages globally in the container
# Note: uv sync will read from pyproject.toml
RUN cd /app && uv pip install --system rich structlog strip-ansi

# Configure Nginx to serve the static website
# Copy our custom configuration and remove the default site
RUN rm -f /etc/nginx/sites-enabled/default
COPY nginx.conf.example /etc/nginx/sites-available/llmeval.conf
RUN ln -sf /etc/nginx/sites-available/llmeval.conf /etc/nginx/sites-enabled/llmeval.conf

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

# Setup cron for daily evaluation runs
# The entrypoint script will install the actual cron job
RUN touch /var/log/cron.log

# Create systemd service for our application initialization
RUN cat > /etc/systemd/system/llmeval-init.service <<'EOF'
[Unit]
Description=LLMEval Initialization Service
After=network.target

[Service]
Type=oneshot
ExecStart=/app/scripts/init-services.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable nginx, cron, and our custom init service
RUN systemctl enable nginx cron llmeval-init

# Expose port 80 for nginx web server
EXPOSE 80

# Systemd requires these volumes to function properly
# These preserve systemd's runtime state between container stops/starts
VOLUME [ "/sys/fs/cgroup" ]

# Stop systemd wanting to mount cgroups itself
STOPSIGNAL SIGRTMIN+3

# Use systemd as PID 1
# systemd will properly delegate cgroups, allowing nested containers to work
CMD ["/lib/systemd/systemd"]
