#!/bin/bash
# Cross-platform Docker installation script
# Supports: Ubuntu/Debian (EC2) and macOS

# Detect OS
OS="$(uname -s)"
echo "[ℹ️] Detected OS: $OS"

if [[ "$OS" == "Linux" ]]; then
    # Ubuntu/Debian installation
    echo "[+] Updating package index..."
    sudo apt-get update

    echo "[+] Installing Docker from Ubuntu repositories..."
    sudo apt-get install -y docker.io docker-compose

    # Verify installation
    if ! command -v docker &> /dev/null; then
        echo "[✗] Docker installation failed"
        exit 1
    fi

    echo "[+] Starting and enabling Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker

    echo "[+] Adding current user to docker group..."
    sudo usermod -aG docker "$USER"

    echo "[✔] Docker installation complete!"
    docker --version
    echo "[ℹ️] Note: You may need to log out and back in for group changes to take effect"

elif [[ "$OS" == "Darwin" ]]; then
    # macOS installation
    echo "[+] Installing Docker Desktop for macOS..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "[✗] Homebrew not found. Please install Homebrew first:"
        echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    # Install Docker Desktop via Homebrew Cask
    if brew list --cask docker &> /dev/null; then
        echo "[ℹ️] Docker Desktop already installed"
    else
        echo "[+] Installing Docker Desktop..."
        brew install --cask docker
    fi

    # Verify installation
    if ! command -v docker &> /dev/null; then
        echo "[⚠️] Docker command not found. Please start Docker Desktop application manually."
        echo "    Applications -> Docker.app"
        exit 1
    fi

    echo "[✔] Docker installation complete!"
    docker --version
    echo "[ℹ️] Make sure Docker Desktop app is running"

else
    echo "[✗] Unsupported operating system: $OS"
    echo "    This script supports Linux (Ubuntu/Debian) and macOS (Darwin)"
    exit 1
fi
