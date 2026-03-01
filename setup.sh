#!/bin/bash
# Pipe Dream Setup Script

set -e

ENV_CREATED=false

# Root .env (only if it doesn't exist)
if [ ! -f ".env" ]; then
    echo "Creating .env..."
    cat > .env << 'EOF'
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
EOF
    ENV_CREATED=true
else
    echo "Using existing .env file"
fi

# Backend virtual environment
if [ ! -d "backend/.venv" ]; then
    echo "Creating backend virtual environment..."
    python3 -m venv backend/.venv
    source backend/.venv/bin/activate
    python -m pip install --upgrade pip
    python -m pip install --upgrade setuptools wheel
    python -m pip install -r backend/requirements.txt
    deactivate
else
    echo "Using existing backend virtual environment"
fi

# Node.js setup with nvm
export NVM_DIR="$HOME/.nvm"

if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "Loading nvm..."
    source "$NVM_DIR/nvm.sh"
    
    if [ -f ".nvmrc" ]; then
        NODE_VERSION=$(cat .nvmrc)
        echo "Installing Node.js $NODE_VERSION..."
        nvm install "$NODE_VERSION"
        nvm use "$NODE_VERSION"
    fi
    
    echo "Installing Node.js packages..."
    npm ci
else
    echo "nvm not found - skipping Node.js setup"
    echo "To install nvm: https://github.com/nvm-sh/nvm"
fi

echo
echo "Setup complete!"

if [ "$ENV_CREATED" = true ]; then
    echo
    echo "IMPORTANT: Update MONGO_URI in .env with your MongoDB connection string"
fi
