#!/bin/bash

set -e  # Exit if any command fails

# Variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/docker_requirements/install_docker.sh"

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "🐳 Starting Docker installation process..."

# Check if Docker is already installed
if command -v docker >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version)
    log "ℹ️  Docker is already installed: $DOCKER_VERSION"
    
    # Check if docker service is running
    if sudo systemctl is-active --quiet docker; then
        log "✅ Docker service is running"
    else
        log "⚠️  Docker is installed but service is not running. Starting Docker..."
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    # Add current user to docker group if not already added
    if ! groups | grep -q docker; then
        log "🔧 Adding current user to docker group..."
        sudo usermod -aG docker $USER
        log "ℹ️  User added to docker group (may require re-login)"
    fi
    
    exit 0
fi

log "🔧 Docker not found. Installing Docker..."

# Check if install script exists
if [ ! -f "$INSTALL_SCRIPT" ]; then
    log "❌ Installation script not found at: $INSTALL_SCRIPT"
    exit 1
fi

# Make install script executable
chmod +x "$INSTALL_SCRIPT"

# Run the installation script
log "🚀 Running Docker installation script..."
"$INSTALL_SCRIPT"

if [ $? -eq 0 ]; then
    log "✅ Docker installation completed successfully!"
    docker --version
    log "=========================================="
    log "✅ All steps completed."
    log "ℹ️  Note: You may need to log out and back in for docker group changes to take effect."
else
    log "❌ Docker installation failed."
    exit 1
fi