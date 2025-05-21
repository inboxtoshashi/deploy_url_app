#!/bin/bash

# Navigate to the Terraform directory
cd /path/to/your/terraform-repo

# Get the EC2 public IP from Terraform output
EC2_IP=$(terraform output -raw ec2_public_ip)

echo "✅ EC2 Public IP is $EC2_IP"

# SSH into the EC2 using the IP
ssh -i "your-key.pem" ec2-user@$EC2_IP << EOF
    echo "🔧 Installing requirements..."
    bash -s < install_requirements/download_docker.sh

    echo "🚀 Deploying app..."
    bash -s < deploy_app/deploy_app.sh
EOF
