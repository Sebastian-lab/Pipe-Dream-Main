#!/bin/bash
set -e

echo "=== Cloudflare Quick Tunnel for Pipe-Dream ==="
echo ""

install_cloudflared() {
    if command -v cloudflared &> /dev/null; then
        cloudflared --version
        return 0
    fi
    
    echo "Installing cloudflared..."
    OS=$(uname -s)
    ARCH=$(uname -m)
    
    case "$OS" in
        Linux)
            [ "$ARCH" = "x86_64" ] && URL="cloudflared-linux-amd64" || URL="cloudflared-linux-arm64"
            ;;
        Darwin)
            [ "$ARCH" = "arm64" ] && URL="cloudflared-darwin-arm64" || URL="cloudflared-darwin-amd64"
            ;;
    esac
    
    curl -L --output /tmp/cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/$URL"
    chmod +x /tmp/cloudflared
    sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
}

install_cloudflared

TEMP_DIR=$(mktemp -d)

cleanup() {
    echo ""
    echo "Stopping tunnel..."
    [ -n "$TUNNEL_PID" ] && kill $TUNNEL_PID 2>/dev/null
    rm -rf "$TEMP_DIR"
    exit 0
}

trap cleanup EXIT INT

echo "Starting tunnel to nginx (port 80)..."
cloudflared tunnel --url localhost:8080 > "$TEMP_DIR/tunnel.log" 2>&1 &
TUNNEL_PID=$!

echo "Waiting for tunnel URL..."
for i in {1..20}; do
    sleep 1
    TUNNEL_URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' "$TEMP_DIR/tunnel.log" 2>/dev/null | head -1)
    if [ -n "$TUNNEL_URL" ]; then
        break
    fi
done

if [ -z "$TUNNEL_URL" ]; then
    echo "Error getting tunnel URL. Check logs:"
    cat "$TEMP_DIR/tunnel.log"
    exit 1
fi

echo ""
echo "=================================="
echo "Tunnel ready!"
echo ""
echo "App URL: $TUNNEL_URL"
echo ""
echo "This URL serves both frontend and backend"
echo "=================================="

# Update .env.local
cd "$(dirname "$0")/.."
cp .env.local .env.local.bak 2>/dev/null || true
sed -i "s|VITE_API_URL=.*|VITE_API_URL=$TUNNEL_URL|" .env.local

echo ""
echo "Updated .env.local with tunnel URL"
echo ""
echo "Next steps:"
echo "1. docker compose up --build"
echo "2. Visit: $TUNNEL_URL"
echo ""
echo "Press Ctrl+C to stop tunnel"
echo ""

wait
