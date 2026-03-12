# Pipe-Dream

A data pipelining project focused on weather forecasting and analysis using machine learning. Built as a full-stack application with MongoDB, secured API, and deployed on AWS EC2 through Cloudflare Tunnel.

## Related Repositories

### [Pipe-Dream-Data-Collection](https://github.com/Sebastian-lab/Pipe-Dream-Data-Collection)
&nbsp;
Data collection repository which runs every minute an on AWS EC2 instance.

### [Pipe-Dream-Machine-Learning](https://github.com/Sebastian-lab/Pipe-Dream-Machine-Learning)
&nbsp;
Includes the weather forecasting and clustering models.

## Prerequisites

- Docker 29.2.1+
- Python 3.12+ (`./setup.sh --py` installs the packages below into a virtual)
    - FastAPI
    - Uvicorn
    - Pydantic
    - PyMongo
    - Certifi
    - python-dotenv
- Node.js 20+ (`./setup.sh --npm` installs the packages below, also works with [nvm](https://github.com/nvm-sh/nvm))
    - Vite
    - TypeScript
    - express
    - cors
    - dotenv
    - Mongoose

## Quick Start

### 1. Setup environment

    ./setup.sh --dev

Creates a `.env` file, installs Python packages in a virtual environment, and installs npm packages locally.

### 2. Add your MongoDB URI

`MONGO_URI=YOUR_MONGO_URI_HERE` in `.env` (line 2)

### 3. Start locally with Docker

    docker compose -f docker-compose.local.yml up --build

This starts two containers: the `frontend` container running Vite and the `backend` container running Uvicorn. If you run in detached mode, you stop them with `docker compose -f docker-compose.local.yml down`.

### 4. Open Pipe-Dream in your browser

http://localhost:5173/

---

## Deployment Options

### 1. Local Development

    docker compose -f docker-compose.local.yml up --build

Access via localhost or network.

### 2. Quick Tunnel (Cloudflare)

    docker compose -f docker-compose.quick-tunnel.yml up --build

Access via Cloudflare tunnel URL (output in console). No ports exposed.

### 3. Production

    docker compose up --build

This command builds and starts three containers:

| Container | Description |
|-----------|-------------|
| `backend` | Uvicorn server running the API on port 8000 |
| `nginx` | Serves the statically-built Vite frontend and proxies `/api` requests to the backend |
| `cloudflared` | Establishes a secure Cloudflare Tunnel for public access via your custom domain |

Once running, the application is accessible through your Cloudflare-managed domain. No public ports need to be opened on your server.

---

## Environment Variables

All configuration is in a single `.env` file at the project root.

```env
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
# Required permissions:
#   Account > Cloudflare Tunnel:Edit
#   Zone > DNS:Edit
CLOUDFLARE_API_TOKEN=
# Get from Cloudflare Dashboard > Overview > Account ID (at the bottom)
CLOUDFLARE_ACCOUNT_ID=
```

### Setting Up MongoDB

1. Get your MongoDB connection string (e.g., from MongoDB Atlas)
2. Edit `.env`:
    ```
    MONGO_URI=mongodb+srv://username:password@cluster.xxx.mongodb.net/?appName=Pipe-Dream
    ```

---

## Architecture

```
Internet
    ↓
Cloudflare Tunnel
    ↓
nginx:80 → frontend (static files)
         ↘ backend (FastAPI on :8000)
```

| Service | Port | Purpose |
|---------|------|---------|
| frontend | 5173 | Vite dev server (local only) |
| nginx | 80 | Serves frontend static files, proxies API requests to backend |
| backend | 8000 | FastAPI application |
| cloudflared | - | Creates secure tunnel to the internet via Cloudflare; exposes nginx on port 80 internally |

---

## Common Commands

```bash
# Build and start
docker compose -f docker-compose.<variant>.yml up --build

# Start in background
docker compose -f docker-compose.<variant>.yml up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f nginx
docker compose logs -f backend
docker compose logs -f cloudflared
```

---

## Development without Docker

### Backend

```bash
# Activate virtual environment
source backend/.venv/bin/activate

# Run backend
cd backend
python3 main.py
```

The backend runs at http://localhost:8000

### Frontend

```bash
# Install Node dependencies (if needed)
npm ci

# Run frontend
npm run dev -- --host
```

The frontend runs at http://localhost:5173

### API Proxy

The frontend vite.config.js proxies `/api/*` requests to the backend:

```javascript
proxy: {
    '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
    },
}
```

---

## Troubleshooting

### CORS Errors

- Ensure `CORS_ORIGINS=*` in `.env` for quick tunnel/production
- For local development, use: `CORS_ORIGINS=http://localhost:5173`

### MongoDB Connection

- Verify `MONGO_URI` is correct in `.env`
- Check network connectivity
- Ensure your IP is allowlisted in MongoDB Atlas (if using Atlas)

### Frontend Not Loading

- Check nginx logs: `docker compose logs nginx`
- Ensure backend is running: `docker compose logs backend`

### Tunnel Not Working

- Check cloudflared logs: `docker compose logs cloudflared`
- Verify cloudflared container is running: `docker ps`

---

## Security Notes

- Change default `API_KEY` for production
- Never commit actual credentials to git
- Use `CORS_ORIGINS=*` only for development/tunnel; use specific domains in production
- The `.env` file is already in `.gitignore`

---

## Testing

```bash
./test_security.sh
```
