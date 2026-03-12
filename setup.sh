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

    local api_token
    api_token=$(grep "^CLOUDFLARE_API_TOKEN=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2-)

    if [ -z "$api_token" ]; then
        echo "CLOUDFLARE_API_TOKEN not set in .env."
        echo "Get a token from: Cloudflare Dashboard > API Tokens > Create Custom Token"
        echo "Required permissions: Account > Cloudflare Tunnel:Edit, Zone > DNS:Edit"
        return 1
    fi

    if ! command -v cloudflared &> /dev/null; then
        echo "cloudflared not found. Installing..."
        install_cloudflared || return 1
    fi

    local tunnel_name="pipe-dream"
    local account_id
    local tunnel_id
    local tunnel_token

    account_id=$(grep "^CLOUDFLARE_ACCOUNT_ID=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2-)

    if [ -z "$account_id" ]; then
        echo "Getting Cloudflare account ID..."
        account_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
            -H "Authorization: Bearer $api_token" \
            -H "Content-Type: application/json" | grep -o '"id":"[a-f0-9-]*"' | head -1 | cut -d'"' -f4)
    fi

    if [ -z "$account_id" ]; then
        echo "Failed to get account ID. Add CLOUDFLARE_ACCOUNT_ID to .env manually."
        return 1
    fi
    echo "Using Account ID: $account_id"

    local existing_tunnel
    existing_tunnel=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$account_id/cfd_tunnel" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" | grep -o "\"name\":\"$tunnel_name\"" || true)

    if [ -n "$existing_tunnel" ]; then
        echo "Tunnel '$tunnel_name' already exists. Getting details..."
        tunnel_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$account_id/cfd_tunnel" \
            -H "Authorization: Bearer $api_token" \
            -H "Content-Type: application/json" | grep -o '"id":"[a-f0-9-]*"' | head -1 | cut -d'"' -f4)
        
        echo "Getting tunnel token..."
        tunnel_token=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$account_id/cfd_tunnel/$tunnel_id/token" \
            -H "Authorization: Bearer $api_token" \
            -H "Content-Type: application/json" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        
        if [ -z "$tunnel_token" ]; then
            echo "Token not available via API. Deleting and recreating tunnel..."
            curl -s -X DELETE "https://api.cloudflare.com/client/v4/accounts/$account_id/cfd_tunnel/$tunnel_id" \
                -H "Authorization: Bearer $api_token" \
                -H "Content-Type: application/json"
            
            echo "Creating new tunnel..."
            local create_response
            create_response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$account_id/cfd_tunnel" \
                -H "Authorization: Bearer $api_token" \
                -H "Content-Type: application/json" \
                -d "{\"name\": \"$tunnel_name\", \"config_src\": \"cloudflare\"}")

            tunnel_id=$(echo "$create_response" | grep -o '"id":"[a-f0-9-]*"' | cut -d'"' -f4)
            tunnel_token=$(echo "$create_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        fi
    else
        echo "Creating Cloudflare Tunnel: $tunnel_name"
        local create_response
        create_response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$account_id/cfd_tunnel" \
            -H "Authorization: Bearer $api_token" \
            -H "Content-Type: application/json" \
            -d "{\"name\": \"$tunnel_name\", \"config_src\": \"cloudflare\"}")

        if ! echo "$create_response" | grep -q '"success":true'; then
            echo "Failed to create tunnel: $create_response"
            return 1
        fi

        tunnel_id=$(echo "$create_response" | grep -o '"id":"[a-f0-9-]*"' | cut -d'"' -f4)
        tunnel_token=$(echo "$create_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        echo "Tunnel created with ID: $tunnel_id"
    fi

    local zone_id
    zone_id=$(echo "$domain" | grep -oP '\.[^.]+$' | head -1)
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain#$zone_id.}" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" | grep -o '"id":"[a-f0-9-]*"' | head -1 | cut -d'"' -f4)

    if [ -n "$zone_id" ]; then
        for subdomain in "$domain" "www.$domain"; do
            echo "Checking DNS record for $subdomain..."
            local existing_record
            existing_record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$subdomain" \
                -H "Authorization: Bearer $api_token" \
                -H "Content-Type: application/json" | grep -o '"id":"[a-f0-9-]*"' | head -1 | cut -d'"' -f4)
            
            if [ -n "$existing_record" ]; then
                echo "Deleting old DNS record for $subdomain..."
                curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$existing_record" \
                    -H "Authorization: Bearer $api_token" \
                    -H "Content-Type: application/json" | grep -q '"success":true' || true
            fi
            
            echo "Creating DNS record for $subdomain..."
            curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
                -H "Authorization: Bearer $api_token" \
                -H "Content-Type: application/json" \
                -d "{\"type\": \"CNAME\", \"name\": \"$subdomain\", \"content\": \"$tunnel_id.cfargotunnel.com\", \"proxied\": true}" | grep -q '"success":true' || true
            echo "DNS record created for $subdomain"
        done
    fi

    if [ -z "$tunnel_token" ]; then
        echo "Getting tunnel token..."
        tunnel_token=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$account_id/cfd_tunnel/$tunnel_id/token" \
            -H "Authorization: Bearer $api_token" \
            -H "Content-Type: application/json" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    fi

    echo "Saving tunnel token..."
    mkdir -p "$CLOUDFLARED_DIR"
    echo "$tunnel_token" > "$CLOUDFLARED_DIR/token"
    chmod 644 "$CLOUDFLARED_DIR/token"

    cat > "$CLOUDFLARED_DIR/config.yml" << EOF
ingress:
  - hostname: $domain
    service: http://nginx:80
  - hostname: www.$domain
    service: http://nginx:80
  - service: http_status:404
EOF

    if grep -q "^CLOUDFLARE_TOKEN=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^CLOUDFLARE_TOKEN=.*|CLOUDFLARE_TOKEN=$tunnel_token|" "$ENV_FILE"
    else
        echo "CLOUDFLARE_TOKEN=$tunnel_token" >> "$ENV_FILE"
    fi

    echo
    echo "Cloudflare Tunnel setup complete!"
    echo "Tunnel ID: $tunnel_id"
    echo "Token saved to .env as CLOUDFLARE_TOKEN"
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

# --- Cloudflare Configuration ---
# Get from Cloudflare Dashboard > API Tokens > Create Custom Token
# Required permissions: Account > Cloudflare Tunnel:Edit, Zone > DNS:Edit
CLOUDFLARE_API_TOKEN=
# Get from Cloudflare Dashboard > Overview > Account ID (at the bottom)
CLOUDFLARE_ACCOUNT_ID=
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
