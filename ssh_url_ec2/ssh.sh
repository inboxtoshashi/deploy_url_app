#!/bin/bash

# Navigate to the Terraform directory
cd /var/lib/jenkins/workspace/url-infra/

# Get the EC2 public IP from Terraform output
EC2_IP=$(terraform output -raw public_ip)

echo "✅ EC2 Public IP is $EC2_IP"

# SSH into the EC2 using the IP
ssh -i "url_app.pem" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    ubuntu@$EC2_IP << EOF
    echo "🔧 Installing requirements..."
    bash -s < install_requirements/download_docker.sh

    echo "🚀 Deploying app..."
    bash -s < deploy_app/deploy_app.sh
EOF



