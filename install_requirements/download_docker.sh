#!/bin/bash

# Clone the repository
git clone https://github.com/inboxtoshashi/docker_requirements.git

echo "✅ Repo cloned"

cd docker_requirements

# Run the Docker install script
echo "🐳 Installing Docker..."
sudo sh install_docker -y

echo "✅ Docker environment setup complete."