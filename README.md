# Watson Orchestrate Proxy for Tasklet.ai

A production-ready proxy server that enables Tasklet.ai to connect to IBM Watson Orchestrate by handling JWT authentication transparently.

## 🚀 Quick Start

### Production URL
```
https://watsonx-proxy-production.up.railway.app
```

### Local Development
```bash
npm install
npm start
```

## ✨ Features

- **Automatic JWT Token Management**: Handles token generation and refresh automatically
- **Rate Limiting**: Built-in protection against abuse (100 req/min default)
- **Retry Logic**: Automatic retry with exponential backoff for failed requests
- **Health Monitoring**: Health check endpoints with detailed status
- **CORS Support**: Configurable CORS for browser-based clients
- **Graceful Shutdown**: Proper cleanup on termination
- **Production Ready**: Optimized for Railway deployment with v1.1.0 improvements
- Error handling and logging
- Railway deployment ready

## Environment Variables

Set these in Railway dashboard:

| Variable | Description | Default |
|----------|-------------|---------|
| `WATSONX_API_KEY` | Your Watsonx API key | (included in code) |
| `WATSONX_INSTANCE_ID` | Your Watsonx instance ID | `20251101-2338-1901-402d-f441a2b6b26b` |
| `PORT` | Server port | `3000` |

## Endpoints

- `GET /` - Service info
- `GET /health` - Health check with token validation
- `ANY /*` - Proxies all requests to Watsonx API

## Deployment to Railway

1. Push to GitHub:
```bash
cd watsonx-proxy
git init
git add .
git commit -m "Initial Watsonx proxy for Tasklet"
git remote add origin YOUR_GITHUB_REPO_URL
git push -u origin main
```

2. In Railway:
   - Create new project
   - Deploy from GitHub repo
   - Select this repository
   - Railway will auto-detect Node.js and deploy

3. Get your URL:
   - It will be something like: `https://watsonx-proxy-production.up.railway.app`

4. Configure Tasklet:
   - Base URL: Your Railway URL
   - Authentication: None

## Local Development

```bash
npm install
npm start
# Visit http://localhost:3000/health
```

## How It Works

1. Tasklet makes request to proxy (no auth needed)
2. Proxy gets/uses cached JWT token from Watsonx
3. Proxy forwards request with Bearer token
4. Response returned to Tasklet

This bypasses Tasklet's JWT validation issues while maintaining security.