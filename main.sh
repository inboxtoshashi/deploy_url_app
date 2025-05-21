#!/bin/bash

set -e  # Exit if any command fails

# Step 1: SSH into EC2
echo "🔐 SSHing into EC2..."
bash ssh_url_ec2/ssh.sh

# Step 2: Install Jenkins & Docker dependencies
echo "⚙️ Installing Jenkins-related configuration..."
bash install_requirements/download_docker.sh

# Step 3: Deploy the URL Shortener App
echo "🚀 Deploying URL Shortener App..."
bash deploy_app/deploy_app.sh

echo "✅ All steps completed successfully."