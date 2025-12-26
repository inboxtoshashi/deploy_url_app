#!/bin/bash

# Variables
TERRAFORM_DIR="/var/lib/jenkins/workspace/url-infra"
SSH_KEY="~/.ssh/url_app.pem"
REMOTE_USER="ubuntu"
REMOTE_DIR="/home/ubuntu"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)/url-app"

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Validate required commands
for cmd in terraform scp ssh; do
    if ! command -v $cmd &> /dev/null; then
        log "❌ Command '$cmd' is not installed. Please install it and try again."
        exit 1
    fi
done

# Go to Terraform directory
cd "$TERRAFORM_DIR" || { log "❌ Failed to change directory to $TERRAFORM_DIR."; exit 1; }

# Get the EC2 public IP
EC2_IP=$(terraform output -raw public_ip)
if [ $? -ne 0 ]; then
    log "❌ Failed to retrieve EC2 public IP."
    exit 1
fi
log "✅ EC2 Public IP is $EC2_IP"

# Move to project root
cd "$PROJECT_ROOT" || { log "❌ Failed to change directory to $PROJECT_ROOT."; exit 1; }

# Copy scripts to EC2
log "🔧 Copying scripts to EC2..."
scp -i "$SSH_KEY" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    install_requirements/download_docker.sh \
    deploy_app/deploy_app.sh \
    "$REMOTE_USER@$EC2_IP:$REMOTE_DIR/"
if [ $? -ne 0 ]; then
    log "❌ Failed to copy scripts to EC2."
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
dos2unix download_docker.sh deploy_app.sh

chmod +x download_docker.sh
./download_docker.sh

chmod +x deploy_app.sh
./deploy_app.sh
EOF

if [ $? -ne 0 ]; then
    log "❌ Failed to execute scripts on EC2."
    exit 1
fi

log "✅ All scripts executed successfully."
