# Environment Setup Guide

## 📁 Files Created

- `backend/.env` - Main configuration
- `backend/.env.local` - Local overrides
- `.env.local` - Frontend variables

## 🔐 Required Setup

### 1. MongoDB Connection
Edit `backend/.env`:
```
MONGO_URI=YOUR_MONGO_URI_HERE
```
Replace with your MongoDB connection string.

### 2. API Key (Optional)
Change the default development key:
```
API_KEY=your_secure_api_key_here
```

## 🌐 Network Access

### Local Development (Default)
```
CORS_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
```

### Local Network
```
CORS_ORIGINS=http://localhost:5173,http://192.168.*.*
```

## 🚀 Start Application

```bash
# Backend
source .venv/bin/activate
cd backend
python3 main.py

# Frontend (new terminal)
npm run dev -- --host
```

## 🔒 Security Notes

- Change default API keys for production
- Never commit actual credentials
- Use HTTPS in production

## 🧪 Test

```bash
./test_security.sh
```

## 🆘 Troubleshooting

### CORS Errors
- Check CORS_ORIGINS in .env files
- Ensure frontend URL is allowed

### Database Connection
- Verify MONGO_URI is correct
- Check network connectivity
