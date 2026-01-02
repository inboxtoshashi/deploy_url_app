#!/bin/bash
set -e
echo "[+] Updating package index..."
sudo apt-get update
echo "[+] Installing required packages..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release
echo "[+] Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null || \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.gpg.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.gpg 2>/dev/null || sudo chmod a+r /etc/apt/keyrings/docker.gpg.asc 2>/dev/null
echo "[+] Setting up Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

echo "[+] Installing Docker Engine..."
# Try installing all packages together first
if sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1 | tee /tmp/docker-install.log; then
    echo "[✔] All Docker packages installed successfully"
else
    echo "[!] Installation encountered errors, trying alternative approach..."
    
    # Install core Docker packages without containerd.io if it's the problem
    if grep -q "containerd.io" /tmp/docker-install.log && grep -q "404" /tmp/docker-install.log; then
        echo "[!] containerd.io version not found, installing Docker without it..."
        sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin || {
            echo "[!] Retrying with --fix-missing..."
            sudo apt-get update --fix-missing
            sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
        }
        
        # Try to install any available version of containerd.io
        echo "[!] Attempting to install any available containerd.io version..."
        sudo apt-get install -y containerd.io || echo "[!] Skipping containerd.io, Docker should still work"
    else
        echo "[!] Retrying with --fix-missing..."
        sudo apt-get update --fix-missing
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
fi

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER"
echo "[✔] Docker installation complete!"
docker --version
