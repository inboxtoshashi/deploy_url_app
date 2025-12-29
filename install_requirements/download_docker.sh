#!/bin/bash

set -e  # Exit if any command fails

# Variables
REPO_URL="https://github.com/inboxtoshashi/docker_requirements.git"
INSTALL_SCRIPT="install_docker"
CLONE_DIR="docker_requirements"

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "🐳 Starting Docker installation process..."

# Check if Docker is already installed
if command -v docker &> /dev/null; then
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

# Clone the repository if it doesn't already exist
if [ ! -d "$CLONE_DIR" ]; then
    log "📥 Cloning docker_requirements repository..."
    git clone "$REPO_URL" "$CLONE_DIR"
    if [ $? -ne 0 ]; then
        log "❌ Failed to clone repository."
        exit 1
    fi
    log "✅ Repository cloned."
else
    log "ℹ️  Repository already exists. Using existing clone."
fi

cd "$CLONE_DIR" || { log "❌ Failed to change directory to $CLONE_DIR."; exit 1; }

# Check if install script exists
if [ ! -f "$INSTALL_SCRIPT" ]; then
    log "❌ Install script '$INSTALL_SCRIPT' not found in repository."
    exit 1
fi

# Make install script executable
chmod +x "$INSTALL_SCRIPT"

# Run the Docker install script
log "⚙️  Running Docker installation script..."
sudo sh "$INSTALL_SCRIPT" -y
if [ $? -ne 0 ]; then
    log "❌ Docker installation failed."
    exit 1
fi

# Start Docker service
log "🚀 Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
log "🔧 Adding current user to docker group..."
sudo usermod -aG docker $USER

# Verify installation
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    log "✅ Docker installed successfully: $DOCKER_VERSION"
else
    log "❌ Docker installation verification failed."
    exit 1
fi

log "✅ Docker environment setup complete."
log "ℹ️  Note: You may need to log out and back in for docker group changes to take effect."