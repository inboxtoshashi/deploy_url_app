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

# Ensure curl is available (used for EC2 metadata lookup and troubleshooting)
if ! command -v curl >/dev/null 2>&1; then
    log "ℹ️  curl not found. Installing curl..."
    sudo apt-get update -y
    sudo apt-get install -y curl
fi

# Auto-detect EC2 public IP and export PUBLIC_URL (no manual config)
# - Uses IMDSv2 when available
# - Falls back to IMDSv1 if IMDSv2 token retrieval is blocked
# - If PUBLIC_URL is already set (e.g., domain/ALB), we keep it
if [ -z "${PUBLIC_URL:-}" ]; then
    FRONTEND_PORT_EFFECTIVE="${FRONTEND_PORT:-9090}"
    EC2_PUBLIC_IP=""

    # Try IMDSv2 first
    IMDS_TOKEN=$(curl -sS -m 2 -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 60" || true)
    if [ -n "$IMDS_TOKEN" ]; then
        EC2_PUBLIC_IP=$(curl -sS -m 2 \
            -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
            "http://169.254.169.254/latest/meta-data/public-ipv4" || true)
    else
        # Fallback: IMDSv1 (may be disabled)
        EC2_PUBLIC_IP=$(curl -sS -m 2 "http://169.254.169.254/latest/meta-data/public-ipv4" || true)
    fi

    if [ -n "$EC2_PUBLIC_IP" ]; then
        if [ "$FRONTEND_PORT_EFFECTIVE" = "80" ]; then
            export PUBLIC_URL="http://$EC2_PUBLIC_IP"
        else
            export PUBLIC_URL="http://$EC2_PUBLIC_IP:$FRONTEND_PORT_EFFECTIVE"
        fi
        log "🌐 Detected EC2 public IP: $EC2_PUBLIC_IP"
        log "🌐 Exported PUBLIC_URL: $PUBLIC_URL"
    else
        log "ℹ️  EC2 public IP not detected via IMDS; leaving PUBLIC_URL unset"
    fi
else
    log "ℹ️  PUBLIC_URL already set; using: ${PUBLIC_URL}"
fi

# Check if Docker is installed and user has permission
if ! command -v docker >/dev/null 2>&1; then
    log "❌ Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if user can run docker commands (without sudo)
if ! docker ps >/dev/null 2>&1; then
    log "⚠️  Docker is installed but user cannot run docker commands."
    log "ℹ️  Adding user to docker group and applying changes..."
    sudo usermod -aG docker $USER
    # Apply group changes without logout
    exec sg docker "$0 $@"
fi

# Check if Docker Compose is installed
if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
    log "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Determine which docker compose command to use
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    log "❌ Docker Compose not found"
    exit 1
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
    git pull origin master || log "⚠️  Could not pull latest changes, using existing code."
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
    log "❌ Failed to start containers. Showing logs..."
    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" logs --tail=50
    exit 1
fi
log "✅ Containers started in detached mode."

# Wait additional time for services to fully stabilize
log "⌛ Waiting 30 seconds for services to start and stabilize..."
sleep 30

# Show running containers
log "📊 Verifying running containers..."
$DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps

# Print access URL (best-effort) for automation logs
if [ -n "${PUBLIC_URL:-}" ]; then
    log "🔗 Access the app at: ${PUBLIC_URL}/"
fi

# Check container health - use docker ps directly for more reliable check
log "🏥 Checking container health..."
ACTUAL_RUNNING=$(docker ps -q | wc -l | tr -d ' ')
TOTAL_CONTAINERS=$($DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" config --services | wc -l | tr -d ' ')

log "ℹ️  Running containers: $ACTUAL_RUNNING | Expected: $TOTAL_CONTAINERS"

if [ "$ACTUAL_RUNNING" -ge "$TOTAL_CONTAINERS" ] && [ "$ACTUAL_RUNNING" -gt 0 ]; then
    log "✅ All containers are running successfully!"
    log "=========================================="
    log "✅ Deployment completed successfully!"
    log "🎉 URL Shortener App is now running!"
    log "=========================================="
else
    log "❌ ERROR: Containers failed to start properly!"
    log "📋 Expected $TOTAL_CONTAINERS containers, but only $ACTUAL_RUNNING are running"
    log "📋 Container status:"
    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps -a
    log "📜 Container logs:"
    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" logs --tail=50
    log "=========================================="
    log "❌ Deployment FAILED - Please check logs above"
    log "=========================================="
    exit 1
fi