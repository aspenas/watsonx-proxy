# Watsonx Orchestrate Proxy for Tasklet

This proxy server handles JWT authentication for IBM Watsonx Orchestrate API, designed to work with Tasklet.ai connections.

## Features

- Automatic JWT token generation and refresh
- Token caching (refreshes 5 minutes before expiry)
- CORS enabled for browser-based clients
- Health check endpoints
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