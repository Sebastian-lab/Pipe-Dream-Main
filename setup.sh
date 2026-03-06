#!/bin/bash
# Pipe Dream Setup Script

set -e

ENV_FILE=".env"
CLOUDFLARED_DIR="cloudflared"

detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

install_cloudflared() {
    local os
    os=$(detect_os)

    if [ "$os" = "windows" ]; then
        echo "Windows detected. Please install cloudflared manually or use WSL."
        echo "Download: https://github.com/cloudflare/cloudflared/releases"
        return 1
    fi

    if [ "$os" = "unknown" ]; then
        echo "Unknown OS. Please install cloudflared manually."
        return 1
    fi

    local arch
    arch=$(uname -m)
    if [ "$arch" = "x86_64" ]; then
        arch="amd64"
    elif [ "$arch" = "aarch64" ]; then
        arch="arm64"
    fi

    echo "Installing cloudflared for $os ($arch)..."
    
    local install_dir="/usr/local/bin"
    local install_path="$install_dir/cloudflared"
    
    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}" -o "$install_path" 2>/dev/null
    
    if [ ! -f "$install_path" ] || [ ! -s "$install_path" ]; then
        install_dir="$HOME/.local/bin"
        install_path="$install_dir/cloudflared"
        mkdir -p "$install_dir"
        curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}" -o "$install_path"
    fi
    
    chmod +x "$install_path"
    echo "cloudflared installed to $install_path"
    
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        export PATH="$install_dir:$PATH"
    fi
}

setup_cloudflared_tunnel() {
    local domain
    domain=$(grep "^DOMAIN=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2-)

    if [ -z "$domain" ] || [ "$domain" = "DEFAULT" ] || [ "$domain" = "example.com" ]; then
        echo "DOMAIN not set in .env. Run again after setting DOMAIN=yourdomain.com"
        return 1
    fi

    if ! command -v cloudflared &> /dev/null; then
        echo "cloudflared not found. Installing..."
        install_cloudflared || return 1
    fi

    local tunnel_name="pipe-dream"
    local tunnel_dir="$HOME/.cloudflared"
    local project_tunnel_dir="$CLOUDFLARED_DIR"

    mkdir -p "$tunnel_dir"

    local tunnel_id
    local existing_tunnel
    existing_tunnel=$(cloudflared tunnel list 2>/dev/null | grep "$tunnel_name" || true)

    if [ -n "$existing_tunnel" ]; then
        echo "Tunnel '$tunnel_name' already exists. Updating DNS..."
        cloudflared tunnel route DNS "$tunnel_name" "$domain" 2>/dev/null || true
        echo "Tunnel DNS updated for $domain"
        tunnel_id=$(cloudflared tunnel list | grep "$tunnel_name" | awk '{print $1}')
    else
        echo "Creating Cloudflare Tunnel: $tunnel_name"
        
        if ! cloudflared tunnel create "$tunnel_name" 2>&1 | grep -q "created"; then
            echo
            echo "Tunnel creation requires authentication."
            echo "Run the following commands manually:"
            echo "  1. cloudflared login"
            echo "  2. cloudflared tunnel create $tunnel_name"
            echo "  3. cloudflared tunnel route DNS $tunnel_name $domain"
            echo
            echo "Then run ./setup.sh --cloudflared again"
            return 0
        fi
        
        tunnel_id=$(cloudflared tunnel list | grep "$tunnel_name" | awk '{print $1}')
        
        echo "Pointing $domain to tunnel..."
        cloudflared tunnel route DNS "$tunnel_name" "$domain"
    fi

    echo "Copying credentials to project directory..."
    mkdir -p "$project_tunnel_dir"
    local creds_file
    creds_file=$(ls "$tunnel_dir"/*.json 2>/dev/null | grep -v "cert.pem" | head -n1)
    cp "$creds_file" "$project_tunnel_dir/creds.json"
    chmod 644 "$project_tunnel_dir/creds.json"

    echo "Creating cloudflared config..."
    mkdir -p "$CLOUDFLARED_DIR"
    cat > "$CLOUDFLARED_DIR/config.yml" << EOF
tunnel: $tunnel_id
credentials-file: /etc/cloudflared/creds.json

ingress:
  - hostname: $domain
    service: http://nginx:80
  - service: http://localhost:8090
EOF

    echo
    echo "Cloudflare Tunnel setup complete!"
    echo "Tunnel ID: $tunnel_id"
}

run_env() {
    if [ -f "$ENV_FILE" ]; then
        echo "Using existing .env file"
    else
        echo "Creating .env..."
        cat > "$ENV_FILE" << 'EOF'
# --- Backend Configuration ---
MONGO_URI=YOUR_MONGO_URI_HERE
DB_NAME=weather_db
APP_ENV=development
DEBUG=True

# --- API Security ---
API_KEY=dev_weather_api_key_secure_change_me_later_2024

# --- CORS Origins ---
# Use * for quick tunnel/production, or specific domains for local dev
CORS_ORIGINS=*

# --- Frontend Configuration ---
VITE_API_KEY=dev_weather_api_key_secure_change_me_later_2024
# VITE_API_URL is not needed for production (uses relative /api via nginx)

# --- Domain Configuration ---
DOMAIN=example.com
EOF
        echo ".env created with default values"
    fi
}

run_py() {
    local python_cmd

    if command -v python3 &> /dev/null; then
        python_cmd=python3
    elif command -v python &> /dev/null; then
        python_cmd=python
    else
        echo "Python not found - skipping"
        return 1
    fi

    if [ -d "backend/.venv" ]; then
        echo "Using existing backend virtual environment"
    else
        echo "Creating backend virtual environment..."
        $python_cmd -m venv backend/.venv
        source backend/.venv/bin/activate
        python -m pip install --upgrade pip
        python -m pip install --upgrade setuptools wheel
        python -m pip install -r backend/requirements.txt
        deactivate
    fi
}

run_npm() {
    export NVM_DIR="$HOME/.nvm"

    if [ -s "$NVM_DIR/nvm.sh" ]; then
        echo "Loading nvm..."
        source "$NVM_DIR/nvm.sh"

        if [ -f ".nvmrc" ]; then
            local node_version
            node_version=$(cat .nvmrc)
            echo "Installing Node.js $node_version..."
            nvm install "$node_version"
            nvm use "$node_version"
        fi
    fi

    if command -v npm &> /dev/null; then
        echo "Installing Node.js packages..."
        npm ci
    else
        echo "npm not found - skipping"
        return 1
    fi
}

run_cloudflared() {
    if [ -f "$ENV_FILE" ] && [ ! -s "$ENV_FILE" ]; then
        echo ".env exists but is empty - run --env first"
        return 1
    fi

    if [ ! -f "$ENV_FILE" ]; then
        echo ".env does not exist - run --env first"
        return 1
    fi

    local domain_was_empty=false
    local domain
    domain=$(grep "^DOMAIN=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2-)

    if [ -z "$domain" ] || [ "$domain" = "DEFAULT" ] || [ "$domain" = "example.com" ]; then
        domain_was_empty=true
    fi

    export PATH="$HOME/.local/bin:$PATH"
    
    if command -v cloudflared &> /dev/null; then
        echo "cloudflared already installed"
    else
        install_cloudflared || return 1
    fi

    if [ "$domain_was_empty" = true ]; then
        echo
        echo "First run: cloudflared installed."
        echo "Update DOMAIN in .env, then run ./setup.sh --cloudflared again to create tunnel."
        return 0
    fi

    setup_cloudflared_tunnel
}

show_usage() {
    echo "Usage: ./setup.sh [OPTIONS]"
    echo
    echo "Options:"
    echo "  --all          Run all setup steps"
    echo "  --env          Create/update .env file"
    echo "  --py           Setup Python virtual environment"
    echo "  --npm          Install npm packages"
    echo "  --cloudflared  Install cloudflared and setup tunnel"
    echo "  --help         Show this help message"
    echo
    echo "Examples:"
    echo "  ./setup.sh --all"
    echo "  ./setup.sh --env --py --npm"
    echo "  ./setup.sh --cloudflared"
}

main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi

    local do_env=false
    local do_py=false
    local do_npm=false
    local do_cloudflared=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                do_env=true
                do_py=true
                do_npm=true
                do_cloudflared=true
                ;;
            --env)
                do_env=true
                ;;
            --py)
                do_py=true
                ;;
            --npm)
                do_npm=true
                ;;
            --cloudflared)
                do_cloudflared=true
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done

    if [ "$do_env" = true ]; then
        run_env
    fi

    if [ "$do_py" = true ]; then
        run_py
    fi

    if [ "$do_npm" = true ]; then
        run_npm
    fi

    if [ "$do_cloudflared" = true ]; then
        run_cloudflared
    fi

    echo
    echo "Setup complete!"
}

main "$@"
