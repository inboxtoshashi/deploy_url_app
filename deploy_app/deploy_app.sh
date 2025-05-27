#!/bin/bash

# Clone the repository
git clone https://github.com/inboxtoshashi/urlshortener_docker.git
cd urlshortener_docker

# Wait for 15 seconds after clone
echo "✅ Repo cloned. Waiting for 5 seconds..."
sleep 5

# Build Docker containers with no cache
echo "🔧 Starting Docker build..."
sudo docker compose -f urlShortner.yml build --no-cache

# Bring up the containers in detached mode
echo "🚀 Starting containers..."
sudo docker compose -f urlShortner.yml up -d

# Wait for 30 seconds after bringing up containers
echo "⌛ Waiting for 30 seconds to allow services to stabilize..."
sleep 30

echo "✅ Deployment completed successfully."