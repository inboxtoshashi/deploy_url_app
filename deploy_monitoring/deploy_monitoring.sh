#!/bin/bash

set -e  # Exit if any command fails

# Variables
MONITORING_REPO_URL="https://github.com/inboxtoshashi/monitoring_stack.git"
MONITORING_DIR="monitoring_stack"
DOCKER_COMPOSE_FILE="monitoring.yml"
APP_NAME="${APP_NAME:-App}"  # Default to App if not provided

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "📊 Starting Monitoring Stack deployment..."

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

# Clone the monitoring stack repository if it doesn't already exist
if [ ! -d "$MONITORING_DIR" ]; then
    log "📥 Cloning monitoring_stack repository..."
    git clone "$MONITORING_REPO_URL" "$MONITORING_DIR"
    if [ $? -ne 0 ]; then
        log "❌ Failed to clone monitoring repository."
        exit 1
    fi
    log "✅ Monitoring repository cloned successfully."
else
    log "ℹ️  Monitoring repository already exists. Pulling latest changes..."
    cd "$MONITORING_DIR" || { log "❌ Failed to change directory to $MONITORING_DIR."; exit 1; }
    git pull origin main || log "⚠️  Could not pull latest changes, using existing code."
    cd ..
fi

cd "$MONITORING_DIR" || { log "❌ Failed to change directory to $MONITORING_DIR."; exit 1; }

# Verify docker compose file exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    log "❌ Docker Compose file '$DOCKER_COMPOSE_FILE' not found."
    exit 1
fi

# Substitute APP_NAME in prometheus.yml
log "🔧 Configuring Prometheus with APP_NAME=$APP_NAME..."
envsubst < prometheus/prometheus.yml > prometheus/prometheus.yml.tmp && mv prometheus/prometheus.yml.tmp prometheus/prometheus.yml

# Update Grafana dashboard titles with APP_NAME
log "🔧 Configuring Grafana dashboards with APP_NAME=$APP_NAME..."
for dashboard in grafana/provisioning/dashboards/*.json; do
    if [ -f "$dashboard" ]; then
        sed -i.bak "s/URL Shortener/${APP_NAME}/g" "$dashboard" && rm -f "$dashboard.bak"
    fi
done

# Check if monitoring network exists, if not create it
log "🔌 Checking monitoring network..."
if ! docker network inspect monitoring &> /dev/null; then
    log "🔌 Creating monitoring network..."
    docker network create monitoring
    if [ $? -ne 0 ]; then
        log "❌ Failed to create monitoring network."
        exit 1
    fi
    log "✅ Monitoring network created successfully."
else
    log "✅ Monitoring network already exists."
fi

# Stop existing monitoring containers if any
log "🛑 Stopping existing monitoring containers (if any)..."
$DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" down || log "ℹ️  No existing monitoring containers to stop."

# Force remove any stale containers using monitoring ports
log "🧹 Cleaning up any stale containers on monitoring ports..."
docker ps -a --filter "publish=9100" --filter "publish=9091" --filter "publish=3000" --filter "publish=9115" --filter "publish=8080" -q | xargs -r docker rm -f 2>/dev/null || true

# Pull latest images
log "📥 Pulling latest Docker images..."
$DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" pull
if [ $? -ne 0 ]; then
    log "⚠️  Warning: Failed to pull some images. Continuing with local images."
fi

# Bring up the monitoring containers in detached mode
log "🚀 Starting monitoring containers in detached mode..."
$DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d
if [ $? -ne 0 ]; then
    log "❌ Failed to start monitoring containers."
    exit 1
fi
log "✅ Monitoring containers started successfully."

# Wait for services to stabilize
log "⌛ Waiting 15 seconds for monitoring services to stabilize..."
sleep 15

# Show running containers
log "📊 Verifying running monitoring containers..."
$DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps

# Check container health
log "🏥 Checking monitoring container health..."
RUNNING_CONTAINERS=$($DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps --services --filter "status=running" | wc -l)
TOTAL_CONTAINERS=$($DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps --services | wc -l)

if [ "$RUNNING_CONTAINERS" -eq "$TOTAL_CONTAINERS" ]; then
    log "✅ All monitoring containers are running successfully!"
else
    log "⚠️  Warning: Some monitoring containers may not be running properly."
    log "ℹ️  Running: $RUNNING_CONTAINERS/$TOTAL_CONTAINERS"
fi

log ""
log "=========================================="
log "📊 Monitoring Stack Deployment Complete!"
log "=========================================="
log ""
log "🌐 Access your monitoring services:"
log "  📈 Prometheus: http://$(hostname -I | awk '{print $1}'):9091"
log "  📊 Grafana:    http://$(hostname -I | awk '{print $1}'):3000"
log "     Username: admin"
log "     Password: admin"
log "  🖥️  Node Exporter: http://$(hostname -I | awk '{print $1}'):9100"
log "  🔍 Blackbox Exporter: http://$(hostname -I | awk '{print $1}'):9115"
log "  📦 cAdvisor:   http://$(hostname -I | awk '{print $1}'):8080"
log ""
log "🎉 Monitoring is now active and collecting metrics from ${APP_NAME}!"
