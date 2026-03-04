# Pipe-Dream

A data pipelining project focused on weather forecasting and analysis using machine learning. Built as a full-stack application with MongoDB, secured API, and deployed on AWS EC2 through Cloudflare Tunnel.

## Related Repositories

- ### [Pipe-Dream-Data-Collection](https://github.com/Sebastian-lab/Pipe-Dream-Data-Collection)

- ### [Pipe-Dream-Machine-Learning](https://github.com/Sebastian-lab/Pipe-Dream-Machine-Learning)

## Prerequisites

- Docker 29.2.1+
- Python 3.12+ (`./setup.sh` installs the packages below into a virtual)
    - FastAPI
    - Uvicorn
    - Pydantic
    - PyMongo
    - Certifi
    - python-dotenv
- Node.js 20+ (if you have [nvm](https://github.com/nvm-sh/nvm) `./setup.sh` installs the packages below)
    - Vite
    - TypeScript
    - express
    - cors
    - dotenv
    - Mongoose

## Quick Start

### 1. Setup environment

`./setup.sh`

### 2. Add your MongoDB URI

`MONGO_URI=YOUR_MONGO_URI_HERE` in `.env` (line 2)

### 3. Start locally with Docker

`docker compose -f docker-compose.local.yml up --build`

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

This is not finished yet.

---

## Environment Variables

All configuration is in a single `.env` file at the project root.

```env
# --- Backend Configuration ---
MONGO_URI=your_mongodb_connection_string
DB_NAME=weather_db
APP_ENV=development
DEBUG=True

# --- API Security ---
API_KEY=your_api_key_here

# --- CORS Origins ---
# Use * for production/quick tunnel, or specific domains for local dev
CORS_ORIGINS=*

# --- Frontend Configuration ---
VITE_API_KEY=your_api_key_here
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
Internet → Cloudflare Tunnel (optional) → nginx → frontend (static)
                                              → backend (API)
```

| Service | Port | Purpose |
|---------|------|---------|
| frontend | 5173 | Vite dev server (local only) |
| nginx | 80 | Serves frontend static files, proxies API |
| backend | 8000 | FastAPI application |
| cloudflared | - | Creates tunnel to internet |

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
