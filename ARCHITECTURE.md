# Watson Orchestrate Proxy - Architecture Overview

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Tasklet.ai                            │
│                    (No Authentication)                       │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Watson Orchestrate Proxy v1.1.0                 │
│         https://watsonx-proxy-production.up.railway.app      │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  Rate Limiter                        │   │
│  │              (100 req/min per IP)                    │   │
│  └──────────────────────────────────────────────────────┘   │
│                           │                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                 Token Manager                        │   │
│  │        • JWT Generation from API Key                 │   │
│  │        • Token Caching (2hr validity)                │   │
│  │        • Auto-refresh (5min buffer)                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                           │                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  Request Proxy                       │   │
│  │        • Retry Logic (3x with backoff)              │   │
│  │        • Timeout Handling (30s)                      │   │
│  │        • Header Sanitization                         │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │               Health Monitor                         │   │
│  │        • Periodic health checks (60s)                │   │
│  │        • Memory monitoring                           │   │
│  │        • Uptime tracking                             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────┬────────────────────────────────────┘
                         │ HTTPS + JWT Bearer Token
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  IBM Watson Orchestrate                      │
│         https://api.dl.watson-orchestrate.ibm.com           │
│                                                              │
│  Instance: 20251101-2338-1901-402d-f441a2b6b26b            │
│                                                              │
│  Resources:                                                  │
│  • /v1/orchestrate/agents                                   │
│  • /v1/orchestrate/skills                                   │
│  • /v1/orchestrate/threads                                  │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
watsonx-proxy/
├── index.js                 # Main proxy server (v1.1.0)
├── package.json             # Dependencies and scripts
├── package-lock.json        # Locked dependency versions
├── .env.example            # Environment configuration template
├── .gitignore              # Git ignore patterns
├── Dockerfile              # Production Docker image
├── railway.json            # Railway deployment config
├── README.md               # User documentation
├── ARCHITECTURE.md         # This file
│
├── docs/                   # Documentation
│   ├── deploy-to-railway.md
│   ├── railway-setup.md
│   ├── email-to-tasklet-support-revised.md
│   └── ...
│
├── scripts/                # Utility scripts
│   ├── get-railway-url.sh
│   ├── start-in-new-terminal.sh
│   └── test-tasklet-integration.sh
│
└── archive/                # Old versions
    ├── index-original.js
    └── index-optimized.js
```

## 🔧 Core Components

### 1. **Token Manager**
- Handles JWT token lifecycle
- Caches tokens to reduce API calls
- Auto-refreshes 5 minutes before expiry
- Thread-safe token refresh with promise deduplication

### 2. **Rate Limiter**
- In-memory rate limiting per IP
- Default: 100 requests per minute
- Configurable via environment variables
- Returns 429 with retry-after header

### 3. **Request Proxy**
- Forwards all requests to Watson Orchestrate
- Automatic retry with exponential backoff
- Timeout handling (30s default)
- Preserves relevant headers, removes sensitive ones

### 4. **Health Monitor**
- `/health` endpoint for uptime monitoring
- Memory usage tracking
- Token validity checks
- Periodic background health checks

## 🚀 Deployment

### Railway (Production)
- Auto-deploy from GitHub main branch
- Environment variables via Railway dashboard
- Health checks and auto-restart
- SSL/TLS handled by Railway

### Docker
- Alpine-based minimal image
- Non-root user for security
- Built-in health checks
- Production-ready configuration

### Local Development
- Simple `npm start`
- Hot reload with `npm run dev` (if configured)
- Environment variables via `.env` file

## 🔒 Security Features

1. **No Authentication Storage**: Proxy handles all JWT management
2. **Rate Limiting**: Prevents abuse and DDoS
3. **Header Sanitization**: Removes sensitive headers
4. **Error Sanitization**: Hides details in production
5. **Non-root Docker**: Runs as unprivileged user
6. **CORS Configuration**: Flexible origin control

## 📊 Performance Optimizations

1. **Token Caching**: Reduces latency by ~200ms per request
2. **Connection Pooling**: Reuses HTTP connections
3. **Memory Efficient**: ~70MB RSS in production
4. **Fast Startup**: < 1 second boot time
5. **Graceful Shutdown**: Proper connection cleanup

## 🔄 Request Flow

1. **Client Request** → Tasklet.ai sends request without auth
2. **Rate Check** → Verify request limit not exceeded
3. **Token Check** → Get cached token or generate new
4. **Proxy Request** → Forward to Watson with JWT
5. **Retry Logic** → Retry on failure with backoff
6. **Response** → Return Watson response to client

## 📈 Monitoring & Observability

- **Health Endpoint**: `/health` for monitoring tools
- **Service Info**: `/` for version and status
- **Request Logging**: Configurable log levels
- **Error Tracking**: Detailed error messages in dev mode
- **Memory Tracking**: Heap and RSS monitoring

## 🎯 Design Principles

1. **Simplicity**: Single responsibility - JWT proxy
2. **Reliability**: Automatic retries and health checks
3. **Security**: No credential storage, rate limiting
4. **Performance**: Token caching, connection pooling
5. **Maintainability**: Clean code, proper error handling

## 🔮 Future Enhancements

- [ ] Redis for distributed rate limiting
- [ ] Prometheus metrics endpoint
- [ ] Request/response caching
- [ ] Multiple instance support
- [ ] WebSocket proxy support

---

Built with focus on **production reliability**, **security**, and **performance**.