# Prompt for Tasklet.ai Agent

## Copy and paste this entire message to your Tasklet agent:

---

Please configure the IBM Watson Orchestrate connection with the following updated settings:

**Connection Configuration:**
- **Connection Name**: IBM Watson Orchestrate
- **Base URL**: `https://watsonx-proxy-production.up.railway.app`
- **Authentication Type**: None / No Authentication
- **Allowed Methods**: GET, POST, PUT, PATCH, DELETE

**Important Notes:**
1. The proxy server is now fully operational and handles all JWT authentication internally
2. Do NOT add any authentication headers - the proxy manages this automatically
3. The Railway deployment has been updated with the correct API key

**Available Endpoints to Test:**
- `GET /health` - Returns proxy health status
- `GET /` - Returns service information
- `GET /v1/agents` - List agents (if configured in Watson)
- `GET /v1/skills` - List skills (if configured in Watson)
- `POST /v1/threads` - Create conversation threads
- `POST /v1/completions` - Get AI completions

**Test the Connection:**
After configuration, please test with:
```
GET https://watsonx-proxy-production.up.railway.app/health
```

Expected response:
```json
{
  "status": "healthy",
  "message": "Watsonx proxy is running and authenticated",
  "tokenValid": true,
  "instance": "20251101-2338-1901-402d-f441a2b6b26b"
}
```

The proxy server automatically:
- Generates JWT tokens from IBM IAM
- Caches tokens with 5-minute refresh buffer
- Adds Bearer authentication to all requests
- Forwards responses back to Tasklet

Please confirm once the connection is configured and tested successfully.

---