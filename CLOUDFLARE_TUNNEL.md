# Quick Tunnel Setup (Docker)

This guide covers how to expose your Pipe-Dream app using Cloudflare Quick Tunnel with Docker.

## Architecture

```
Internet → Cloudflare Tunnel → nginx → frontend
                                    → backend
```

## Quick Start

### Terminal 1 - Start tunnel:
```bash
./cloudflared/quick-tunnel.sh
```

This will output:
```
App URL: https://xyz.trycloudflare.com
```

### Terminal 2 - Start Docker:
```bash
docker compose up --build
```

Then visit: **https://xyz.trycloudflare.com**

---

## How It Works

1. **cloudflared** tunnel connects to nginx on port 8080
2. **nginx** routes:
   - `/` → frontend (5173)
   - `/api/*` → backend (8000)
   - `/health` → backend health check
3. **Single URL** serves both frontend and backend (no CORS issues!)

---

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Defines frontend, backend, nginx, cloudflared services |
| `nginx.conf` | Routes requests to appropriate services |
| `cloudflared/quick-tunnel.sh` | Starts the tunnel |

---

## Manual Commands

If you need to run things manually:

```bash
# Build and start all services
docker compose up --build

# Stop all services
docker compose down

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f nginx
docker compose logs -f cloudflared
```

---

## Development (Local without tunnel)

```bash
# Just start nginx on port 8080
docker compose up nginx

# Or start everything without cloudflared
docker compose up frontend backend nginx
```

Then access at http://localhost:8080

---

## Notes

- **URL changes each restart** - You'll get a new URL each time
- **CORS is set to allow all** (`*`) - works automatically
- **No port forwarding needed** - tunnel handles everything
