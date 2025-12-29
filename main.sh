#!/bin/bash

set -e  # Exit if any command fails
set -o pipefail  # Catch errors in piped commands

# Variables
SSH_SCRIPT="ssh_url_ec2/ssh.sh"

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "🚀 Starting URL Shortener App Deployment"
log "=========================================="

# Validate SSH script exists
if [ ! -f "$SSH_SCRIPT" ]; then
    log "❌ Required script '$SSH_SCRIPT' not found. Exiting."
    exit 1
fi

# Make SSH script executable
chmod +x "$SSH_SCRIPT"

# Execute SSH script which will:
# 1. Get EC2 IP from Terraform output
# 2. Copy install and deploy scripts to EC2
# 3. SSH into EC2 and execute the scripts
log "🔐 Connecting to EC2 and deploying application..."
bash "$SSH_SCRIPT"
if [ $? -ne 0 ]; then
    log "❌ Deployment failed. Check the logs above for details."
    exit 1
fi

log "=========================================="
log "✅ All steps completed successfully."
log "🎉 URL Shortener App is now running on EC2!"