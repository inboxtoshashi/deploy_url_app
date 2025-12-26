#!/bin/bash

# Variables
REPO_URL="https://github.com/inboxtoshashi/docker_requirements.git"
INSTALL_SCRIPT="install_docker"
CLONE_DIR="docker_requirements"

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    log "ℹ️ Docker is already installed. Skipping installation."
    exit 0
fi

# Clone the repository if it doesn't already exist
if [ ! -d "$CLONE_DIR" ]; then
    log "🔧 Cloning repository..."
    git clone "$REPO_URL" "$CLONE_DIR"
    if [ $? -ne 0 ]; then
        log "❌ Failed to clone repository."
        exit 1
    fi
    log "✅ Repository cloned."
else
    log "ℹ️ Repository already exists. Skipping clone."
fi

cd "$CLONE_DIR" || { log "❌ Failed to change directory to $CLONE_DIR."; exit 1; }

# Run the Docker install script
log "🐳 Installing Docker..."
sudo sh "$INSTALL_SCRIPT" -y
if [ $? -ne 0 ]; then
    log "❌ Docker installation failed."
    exit 1
fi

log "✅ Docker environment setup complete."