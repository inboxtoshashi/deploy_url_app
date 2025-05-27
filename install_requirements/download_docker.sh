#!/bin/bash

# Clone the repository
git clone https://github.com/inboxtoshashi/docker_requirements.git
# Wait for 15 seconds after clone
echo "✅ Repo cloned. Waiting for 15 seconds..."
sleep 15

cd docker_requirements

# Run the Docker install script
echo "🐳 Installing Docker..."
sudo sh install_docker -y

# Wait for 1 minute after Docker installation to ensure everything settles
echo "⏳ Docker installation finished. Waiting for 1 minute..."
sleep 60

echo "✅ Docker environment setup complete."