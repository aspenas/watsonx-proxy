# Watson Orchestrate Proxy v1.2.0

A production-ready proxy server that enables seamless integration between Tasklet.ai and IBM Watson Orchestrate by handling JWT authentication and instance ID management transparently.

## 🚀 Quick Start

### Production URL
```
https://watsonx-proxy-production.up.railway.app
```

### Local Development
```bash
cp .env.example .env
# Edit .env with your API key
npm install
npm start
```

## ✨ Features

- **JWT Token Management**: Automatic token generation and refresh
- **Instance ID Auto-injection**: Transparently adds instance ID to orchestrate API paths (v1.2.0)
- **Token Caching**: Reduces API calls with intelligent refresh before expiration
- **Rate Limiting**: Built-in protection (100 req/min default)
- **Retry Logic**: Automatic retry with exponential backoff
- **Health Monitoring**: Detailed health checks with token validation
- **CORS Support**: Configurable cross-origin resource sharing
- **Security First**: No hardcoded API keys, environment variables only
- **Graceful Shutdown**: Proper cleanup on termination

## 🔒 Environment Variables

**Required** - Set these in Railway dashboard or `.env` file:

| Variable | Description | Required |
|----------|-------------|----------|
| `WATSONX_API_KEY` | Your IBM Watson API key | ✅ Yes |
| `WATSONX_INSTANCE_ID` | Your Watson instance ID | ✅ Yes |
| `PORT` | Server port | No (default: 3000) |
| `NODE_ENV` | Environment (development/production) | No |

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