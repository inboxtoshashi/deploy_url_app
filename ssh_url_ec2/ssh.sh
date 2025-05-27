#!/bin/bash

# Go to Terraform directory (adjust path if needed)
cd /var/lib/jenkins/workspace/url-infra/

# Get the EC2 public IP
EC2_IP=$(terraform output -raw public_ip)
echo "✅ EC2 Public IP is $EC2_IP"

# Get absolute path to the root of the project
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)/url-app"

# Move to project root
cd "$PROJECT_ROOT"

# Copy scripts to EC2
scp -i ssh_url_ec2/url_app.pem \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    install_requirements/download_docker.sh \
    deploy_app/deploy_app.sh \
    ubuntu@$EC2_IP:/home/ubuntu/

# SSH and execute scripts
ssh -i ssh_url_ec2/url_app.pem \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    ubuntu@$EC2_IP << 'EOF'
cd /home/ubuntu

echo "🔧 Installing Docker..."

# Ensure correct line endings
command -v dos2unix >/dev/null || (sudo apt update && sudo apt install -y dos2unix)
dos2unix download_docker.sh deploy_app.sh

chmod +x download_docker.sh
./download_docker.sh

echo "🚀 Deploying URL Shortener App..."
chmod +x deploy_app.sh
./deploy_app.sh

echo "🧹 Cleaning up old repos if present..."
rm -rf docker_requirements
rm -rf urlshortener_docker
EOF
