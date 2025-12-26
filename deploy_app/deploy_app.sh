#!/bin/bash

# Variables
REPO_URL="https://github.com/inboxtoshashi/urlshortener_docker.git"
DOCKER_COMPOSE_FILE="urlShortner.yml"
CLONE_DIR="urlshortener_docker"

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log "❌ Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    log "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
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

# Build Docker containers with no cache
log "🔧 Starting Docker build..."
docker compose -f "$DOCKER_COMPOSE_FILE" build --no-cache
if [ $? -ne 0 ]; then
    log "❌ Docker build failed."
    exit 1
fi

# Bring up the containers in detached mode
log "🚀 Starting containers..."
docker compose -f "$DOCKER_COMPOSE_FILE" up -d
if [ $? -ne 0 ]; then
    log "❌ Failed to start containers."
    exit 1
fi

# Wait for 5 seconds after bringing up containers
log "⌛ Waiting for 5 seconds to allow services to stabilize..."
sleep 5

log "✅ Deployment completed successfully."