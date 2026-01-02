#!/bin/bash

# Variables
# Environment can be passed as ENV variable (dev or prod), defaults to dev
ENVIRONMENT="${ENV:-dev}"

# Detect platform for state file path
OS="$(uname -s)"

# SSH key path can be configured via SSH_KEY_PATH env variable
SSH_KEY="${SSH_KEY_PATH:-$HOME/.ssh/url_app.pem}"
REMOTE_USER="ubuntu"
REMOTE_DIR="/home/ubuntu"
# Get the directory where this script is located, then go up one level to project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "🌍 Environment: ${ENVIRONMENT}"

# Find terraform binary
TERRAFORM_BIN=$(which terraform 2>/dev/null)
if [ -z "$TERRAFORM_BIN" ]; then
    # Check common locations (Linux first, then macOS)
    for path in /usr/local/bin/terraform /usr/bin/terraform /opt/homebrew/bin/terraform; do
        if [ -f "$path" ]; then
            TERRAFORM_BIN="$path"
            break
        fi
    done
fi

# Validate required commands
if [ -z "$TERRAFORM_BIN" ] || [ ! -f "$TERRAFORM_BIN" ]; then
    log "❌ Command 'terraform' is not installed or not found. Please install it and try again."
    exit 1
fi
log "✅ Using Terraform at: ${TERRAFORM_BIN}"

for cmd in scp ssh; do
    if ! command -v $cmd &> /dev/null; then
        log "❌ Command '$cmd' is not installed. Please install it and try again."
        exit 1
    fi
done

# Determine centralized state file location
if [[ "$OS" == "Darwin" ]]; then
  STATE_FILE="$HOME/.jenkins/workspace/terraform-states/${ENVIRONMENT}/terraform.tfstate"
else
  STATE_FILE="/var/lib/jenkins/workspace/terraform-states/${ENVIRONMENT}/terraform.tfstate"
fi

# Get the EC2 public IP from centralized state
log "🔍 Retrieving EC2 public IP from Terraform state..."
log "State file: ${STATE_FILE}"

if [ ! -f "$STATE_FILE" ]; then
    log "❌ State file not found at ${STATE_FILE}"
    log "💡 Please run Deploy-Infra job first to create infrastructure"
    exit 1
fi

# Extract public_ip from state file using terraform output (no need to cd to terraform dir)
EC2_IP=$("${TERRAFORM_BIN}" output -state="${STATE_FILE}" -raw public_ip 2>/dev/null)

# If terraform output fails, try parsing state JSON directly
if [ $? -ne 0 ] || [ -z "$EC2_IP" ]; then
    log "⚠️  terraform output failed, parsing state file directly..."
    EC2_IP=$(grep -o '"public_ip":[^,}]*' "${STATE_FILE}" | grep -o '[0-9.]*' | head -1)
fi

if [ -z "$EC2_IP" ]; then
    log "❌ Failed to retrieve EC2 public IP from state file."
    exit 1
fi
log "✅ EC2 Public IP is $EC2_IP"

# Verify SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    log "❌ SSH key '$SSH_KEY' not found."
    exit 1
fi

# Move to project root
cd "$PROJECT_ROOT" || { log "❌ Failed to change directory to $PROJECT_ROOT."; exit 1; }
log "📂 Working directory: $PROJECT_ROOT"

# Copy scripts and docker requirements to EC2
log "🔧 Copying scripts to EC2..."
scp -i "$SSH_KEY" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    install_requirements/setup_docker.sh \
    deploy_app/deploy_app.sh \
    "$REMOTE_USER@$EC2_IP:$REMOTE_DIR/"
if [ $? -ne 0 ]; then
    log "❌ Failed to copy scripts to EC2."
    exit 1
fi

# Copy docker_requirements directory recursively
log "🔧 Copying docker_requirements directory to EC2..."
scp -i "$SSH_KEY" -r \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    install_requirements/docker_requirements \
    "$REMOTE_USER@$EC2_IP:$REMOTE_DIR/"
if [ $? -ne 0 ]; then
    log "❌ Failed to copy docker_requirements directory to EC2."
    exit 1
fi

# SSH and execute scripts
log "🔧 Connecting to EC2 and executing scripts..."
ssh -i "$SSH_KEY" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$REMOTE_USER@$EC2_IP" << 'EOF'
cd /home/ubuntu

# Ensure correct line endings
command -v dos2unix >/dev/null || (sudo apt update && sudo apt install -y dos2unix)
dos2unix setup_docker.sh deploy_app.sh

# Install Docker requirements
chmod +x setup_docker.sh
./setup_docker.sh

# Deploy the URL Shortener application
chmod +x deploy_app.sh
./deploy_app.sh
EOF

if [ $? -ne 0 ]; then
    log "❌ Failed to execute scripts on EC2."
    exit 1
fi

log "✅ All scripts executed successfully."