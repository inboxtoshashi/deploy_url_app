#!/bin/bash

set -e  # Exit if any command fails

# Variables
REPO_URL="https://github.com/inboxtoshashi/urlshortener_docker.git"
DOCKER_COMPOSE_FILE="urlShortner.yml"
CLONE_DIR="urlshortener_docker"

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "🚀 Starting URL Shortener App deployment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log "❌ Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    log "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Determine which docker compose command to use
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    DOCKER_COMPOSE_CMD="docker-compose"
fi
log "ℹ️  Using: $DOCKER_COMPOSE_CMD"

# Clone the repository if it doesn't already exist
if [ ! -d "$CLONE_DIR" ]; then
    log "📥 Cloning urlshortener_docker repository..."
    git clone "$REPO_URL" "$CLONE_DIR"
    if [ $? -ne 0 ]; then
        log "❌ Failed to clone repository."
        exit 1
    fi
    log "✅ Repository cloned successfully."
else
    log "ℹ️  Repository already exists. Pulling latest changes..."
    cd "$CLONE_DIR" || { log "❌ Failed to change directory to $CLONE_DIR."; exit 1; }
    git pull origin main || log "⚠️  Could not pull latest changes, using existing code."
    cd ..
fi

cd "$CLONE_DIR" || { log "❌ Failed to change directory to $CLONE_DIR."; exit 1; }

# Verify docker compose file exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    log "❌ Docker Compose file '$DOCKER_COMPOSE_FILE' not found."
    exit 1
fi

# Stop existing containers if any
log "🛑 Stopping existing containers (if any)..."
$DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" down || log "ℹ️  No existing containers to stop."

# Build Docker containers with no cache
log "🔨 Building Docker containers (this may take a few minutes)..."
$DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" build --no-cache
if [ $? -ne 0 ]; then
    log "❌ Docker build failed."
    exit 1
fi
log "✅ Docker build completed successfully."

# Bring up the containers in detached mode
log "🚀 Starting containers in detached mode..."
$DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d
if [ $? -ne 0 ]; then
    log "❌ Failed to start containers."
    exit 1
fi
log "✅ Containers started successfully."

# Wait for services to stabilize
log "⌛ Waiting 10 seconds for services to stabilize..."
sleep 10

# Show running containers
log "📊 Verifying running containers..."
$DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps

# Check container health
log "🏥 Checking container health..."
RUNNING_CONTAINERS=$($DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps --services --filter "status=running" | wc -l)
TOTAL_CONTAINERS=$($DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps --services | wc -l)

if [ "$RUNNING_CONTAINERS" -eq "$TOTAL_CONTAINERS" ]; then
    log "✅ All containers are running successfully!"
else
    log "⚠️  Warning: Some containers may not be running properly."
    log "ℹ️  Running: $RUNNING_CONTAINERS/$TOTAL_CONTAINERS"
fi

log "=========================================="
log "✅ Deployment completed successfully!"
log "🎉 URL Shortener App is now running!"
log "=========================================="