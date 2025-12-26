#!/bin/bash

set -e  # Exit if any command fails
set -o pipefail  # Catch errors in piped commands

# Variables
SSH_SCRIPT="ssh_url_ec2/ssh.sh"
INSTALL_SCRIPT="install_requirements/download_docker.sh"
DEPLOY_SCRIPT="deploy_app/deploy_app.sh"

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Validate required scripts
for script in "$SSH_SCRIPT" "$INSTALL_SCRIPT" "$DEPLOY_SCRIPT"; do
    if [ ! -f "$script" ]; then
        log "❌ Required script '$script' not found. Exiting."
        exit 1
    fi
done

# Step 1: SSH into EC2
log "🔐 SSHing into EC2..."
bash "$SSH_SCRIPT"
if [ $? -ne 0 ]; then
    log "❌ Failed to SSH into EC2. Exiting."
    exit 1
fi

# Step 2: Install Jenkins & Docker dependencies
log "⚙️ Installing Jenkins-related configuration..."
bash "$INSTALL_SCRIPT"
if [ $? -ne 0 ]; then
    log "❌ Failed to install Jenkins-related configuration. Exiting."
    exit 1
fi

# Step 3: Deploy the URL Shortener App
log "🚀 Deploying URL Shortener App..."
bash "$DEPLOY_SCRIPT"
if [ $? -ne 0 ]; then
    log "❌ Failed to deploy the URL Shortener App. Exiting."
    exit 1
fi

log "✅ All steps completed successfully."