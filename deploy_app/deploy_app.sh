#!/bin/bash

# Clone the repository
git clone https://github.com/inboxtoshashi/urlshortener_docker.git
cd urlshortener_docker

# Wait for 15 seconds after clone
echo "✅ Repo cloned. Waiting for 15 seconds..."
sleep 15

# Build Docker containers with no cache
echo "🔧 Starting Docker build..."
sudo docker compose -f urlShortner.yml build --no-cache

# Wait for 2 minutes after build
echo "⏳ Build complete. Waiting for 2 minutes..."
sleep 120

# Bring up the containers in detached mode
echo "🚀 Starting containers..."
sudo docker compose -f urlShortner.yml up -d

# Wait for 30 seconds after bringing up containers
echo "⌛ Waiting for 30 seconds to allow services to stabilize..."
sleep 30

echo "✅ Deployment completed successfully."