# Email to Tasklet.ai Support

**To:** support@tasklet.ai
**Subject:** IBM Watsonx Integration - JWT Token Validation Issue & Working Solution

---

Hi Tasklet Support Team,

I wanted to follow up on the IBM Watson Orchestrate integration issue I reported earlier and share a working solution that might help other users facing similar challenges.

## Original Issue

When attempting to configure IBM Watson Orchestrate as a Direct API Connection in Tasklet, the Bearer authentication fails with the error:
```
"Invalid header value for: Authorization"
```

This occurs because IBM Watsonx uses JWT tokens that are approximately 1,500 characters long, which appears to exceed Tasklet's header validation limits. The same token works perfectly with curl and other HTTP clients.

## Working Solution

I've successfully resolved this by creating a proxy server that handles JWT authentication transparently. This approach allows Tasklet to connect without any authentication, while the proxy manages all token lifecycle operations.

### Proxy Server Details

**Production URL:** https://watsonx-proxy-production.up.railway.app
**GitHub Repository:** [Available if you'd like to review the implementation]

The proxy server:
- Automatically generates JWT tokens from IBM's IAM service
- Caches tokens with intelligent refresh (5 minutes before expiry)
- Forwards all requests to IBM Watsonx with proper Bearer authentication
- Handles all authentication complexity transparently

### Tasklet Configuration (Working)

```
Connection Name: IBM Watson Orchestrate
Base URL: https://watsonx-proxy-production.up.railway.app
Authentication: None / No Auth
Allowed Methods: GET, POST, PATCH, PUT, DELETE
```

### Technical Implementation

The proxy converts this flow:
```
Tasklet → [Needs JWT Bearer Auth] → IBM Watsonx ❌ (Token too long)
```

To this:
```
Tasklet → [No Auth] → Proxy → [JWT Bearer Auth] → IBM Watsonx ✅
```

## Suggestions for Tasklet

1. **Increase Header Size Limits**: Consider increasing the maximum allowed length for Authorization headers to support JWT tokens up to 2,000 characters.

2. **JWT Token Support**: Add native support for JWT token generation from API keys, similar to how OAuth2 flows work.

3. **Custom Auth Headers**: Allow users to define custom authentication flows that can generate tokens programmatically.

## Current Status

The proxy solution is working perfectly and has been deployed to production. It's handling authentication seamlessly, and Tasklet can now interact with IBM Watson Orchestrate without any issues.

## Sample Test Endpoints

Once configured, these endpoints work through the proxy:
- `GET /health` - Health check
- `GET /v1/skills` - List available Watson skills
- `POST /v1/threads` - Create conversation threads
- `POST /v1/completions` - Get AI completions

## Questions

1. Is there a planned update to support longer Bearer tokens in Direct API Connections?
2. Would you be interested in adding IBM Watsonx as a pre-configured integration using this proxy approach?
3. Can the header validation limits be configured on a per-connection basis?

Thank you for your excellent platform. The proxy solution is working well, but native support would be even better for the community.

Best regards,
Patrick Smith

---

**P.S.** If any other Tasklet users need help with IBM Watsonx integration, I'm happy to share the complete proxy implementation. It's a simple Node.js/Express server that can be deployed on Railway, Heroku, or any Node.js hosting platform.