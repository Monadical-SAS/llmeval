#!/bin/bash
set -e

# Install Docker if not available
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker.io > /dev/null 2>&1
    echo "Docker installed"
fi

echo "C++ compilation will use gcc:13 Docker image to avoid host path conflicts"
