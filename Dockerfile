# Dockerfile for LLMEval automated evaluation and static website hosting
# Base: Ubuntu 22.04 LTS for stability and wide package support
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to Central Time (CST/CDT)
ENV TZ=America/Chicago

# Install system dependencies
# - curl, ca-certificates, gnupg: For downloading packages and verifying signatures
# - python3.13, python3-pip: Python runtime and package manager
# - docker-cli: Docker client for cubbi to execute LLM evaluation environments
# - cron: For scheduled evaluation runs
# - git: For potential repository updates and version control
# - tzdata: Timezone data for correct scheduling
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    software-properties-common \
    cron \
    git \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

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

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

# Setup cron for daily evaluation runs
RUN touch /var/log/cron.log

# Use entrypoint script to initialize services
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
