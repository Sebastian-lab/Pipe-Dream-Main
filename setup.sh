#!/bin/bash

# Pipe Dream Setup Script

set -e

echo "Checking for existing environment files..."

# Backend .env (only if it doesn't exist)
if [ ! -f "backend/.env" ]; then
    echo "Creating backend/.env..."
    cat > backend/.env << 'EOF'
# --- Database Configuration ---
MONGO_URI=YOUR_MONGO_URI_HERE
DB_NAME=weather_db

# --- Application Settings ---
APP_ENV=development
DEBUG=True

# --- API Security ---
API_KEY=dev_weather_api_key_secure_change_me_later_2024

# --- CORS Origins ---
CORS_ORIGINS=http://localhost:5173,http://127.0.0.1:5173,http://localhost:3000

# --- External Services ---
OPEN_METEO_URL=https://api.open-meteo.com/v1/forecast
REFRESH_INTERVAL_MINUTES=1
EOF
else
    echo "backend/.env already exists - skipping"
fi

# Backend .env.local (only if it doesn't exist)
if [ ! -f "backend/.env.local" ]; then
    echo "Creating backend/.env.local..."
    cat > backend/.env.local << 'EOF'
# --- Local Development Environment ---
APP_ENV=development
DEBUG=True

# --- API Security ---
API_KEY=dev_weather_api_key_secure_change_me_later_2024

# --- CORS Origins (Local Development) ---
CORS_ORIGINS=http://localhost:5173,http://127.0.0.1:5173,http://localhost:3000

# --- Network Access ---
# You can add your local network ranges here when ready for LAN access:
# CORS_ORIGINS=http://192.168.*.*,http://10.0.*.*

# --- Database Configuration (inherits from main .env) ---
# These settings will be read from the main .env file

# --- External Services ---
OPEN_METEO_URL=https://api.open-meteo.com/v1/forecast
REFRESH_INTERVAL_MINUTES=1
EOF
else
    echo "backend/.env.local already exists - skipping"
fi

# Frontend .env.local (only if it doesn't exist)
if [ ! -f ".env.local" ]; then
    echo "Creating .env.local..."
    cat > .env.local << 'EOF'
# Frontend Environment Variables for Local Development
VITE_API_URL=http://localhost:8000
VITE_API_KEY=dev_weather_api_key_secure_change_me_later_2024
EOF
else
    echo ".env.local already exists - skipping"
fi

echo
echo "Setup complete!"
echo
echo "Next:"
echo "1. Add MONGO_URI to backend/.env (if needed)"
echo -e "2. Start backend:\n\tsource .venv/bin/activate\n\tcd backend\n\tpython3 main.py"
echo -e "3. Start frontend (in a separate terminal):\n\tnpm run dev -- --host"
