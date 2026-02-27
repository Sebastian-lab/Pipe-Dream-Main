#!/bin/bash
set -e

echo "=== Cloudflare Tunnel Setup for Pipe-Dream ==="

TUNNEL_NAME="pipe-dream"
CONFIG_DIR="$HOME/.cloudflared"
CONFIG_FILE="$CONFIG_DIR/config.yml"

install_cloudflared() {
    echo "Installing cloudflared..."
    
    if command -v cloudflared &> /dev/null; then
        echo "cloudflared already installed"
        cloudflared --version
        return 0
    fi
    
    OS=$(uname -s)
    ARCH=$(uname -m)
    
    case "$OS" in
        Linux)
            if [ "$ARCH" = "x86_64" ]; then
                curl -L --output /tmp/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
            elif [ "$ARCH" = "aarch64" ]; then
                curl -L --output /tmp/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
            else
                echo "Unsupported architecture: $ARCH"
                exit 1
            fi
            ;;
        Darwin)
            if [ "$ARCH" = "arm64" ]; then
                curl -L --output /tmp/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64
            else
                curl -L --output /tmp/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64
            fi
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    chmod +x /tmp/cloudflared
    sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
    echo "cloudflared installed successfully"
    cloudflared --version
}

setup_tunnel() {
    echo "Setting up Cloudflare Tunnel..."
    
    mkdir -p "$CONFIG_DIR"
    
    if ! command -v cloudflared &> /dev/null; then
        echo "Error: cloudflared not installed"
        exit 1
    fi
    
    echo "Login to Cloudflare (a browser will open)..."
    cloudflared tunnel login
    
    echo "Creating tunnel: $TUNNEL_NAME"
    cloudflared tunnel create "$TUNNEL_NAME" 2>/dev/null || echo "Tunnel may already exist"
    
    echo "Tunnel created. Run 'cloudflared tunnel list' to verify."
}

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Run: ./cloudflared/setup-tunnel.sh"
echo "2. Configure your tunnel in Cloudflare Dashboard"
echo "3. Update backend/.env with your tunnel URL"
echo ""
