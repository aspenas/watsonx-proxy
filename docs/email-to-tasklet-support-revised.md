# Email to Tasklet.ai Support - Revised

**To:** support@tasklet.ai
**Subject:** IBM Watson Orchestrate Integration - JWT Token Validation Issue & Working Proxy Solution

---

Hi Tasklet Support Team,

I wanted to report an issue with Tasklet's Direct API Connection feature and share a working solution that other users might benefit from.

## The Issue: JWT Token Header Validation

When configuring IBM Watson Orchestrate as a Direct API Connection in Tasklet, the integration fails with this error:
```
"Invalid header value for: Authorization"
```

### Root Cause Analysis

After extensive debugging, I've identified the specific problem:

1. **IBM Watson Orchestrate uses JWT Bearer tokens** that are approximately 1,500-2,000 characters long
2. **Tasklet's header validation** appears to have a character limit that rejects these long tokens
3. **The tokens are valid** - they work perfectly with curl, Postman, and other HTTP clients

### Technical Details

IBM Watson Orchestrate requires a two-step authentication process:
1. Exchange an API key for a JWT token via IBM IAM endpoint
2. Use the JWT token as a Bearer token for all API requests

Example JWT token length from IBM:
```
Authorization: Bearer eyJraWQiOiIyMDI0MTAyOTA4MzQiLCJhbGciOiJSUzI1NiJ9.eyJpYW1faWQiOiJJQk1pZC05NEY2... [continues for ~1500+ characters]
```

When this token is used in Tasklet's Direct API Connection with Bearer authentication, Tasklet's validation rejects it before even attempting the API call.

## Working Solution: Proxy Server

I've successfully resolved this by creating a proxy server that handles JWT authentication transparently:

**Production Proxy URL:** https://watsonx-proxy-production.up.railway.app
**GitHub Repository:** https://github.com/aspenas/watsonx-proxy

### How It Works

```
Tasklet (No Auth) → Proxy Server → (JWT Bearer Auth) → IBM Watson
```

The proxy:
- Automatically generates JWT tokens from IBM IAM
- Caches tokens with intelligent refresh
- Adds Bearer authentication to all outbound requests
- Returns responses transparently to Tasklet

### Tasklet Configuration

With the proxy, configuration is simple:
```
Connection Name: IBM Watson Orchestrate
Base URL: https://watsonx-proxy-production.up.railway.app
Authentication: None / No Auth
Allowed Methods: GET, POST, PATCH, PUT, DELETE
```

## Recommendations for Tasklet

To support IBM Watson and similar services natively, please consider:

### 1. **Increase Authorization Header Limits**
- Current limit appears to be around 500-1000 characters
- IBM JWT tokens require 1,500-2,000 characters
- Many modern cloud services use similarly long JWT tokens

### 2. **Add JWT Token Generation Support**
- Allow API key to JWT token exchange as an authentication method
- Similar to OAuth2 flow but for JWT-based services
- Would eliminate need for proxy servers

### 3. **Improve Error Messages**
- Current error "Invalid header value" doesn't indicate it's a length issue
- Consider: "Authorization header exceeds maximum length of X characters"

### 4. **Document Header Limitations**
- Add documentation about maximum header lengths
- List which authentication methods have limitations

## Impact

This issue affects integration with:
- IBM Watson Orchestrate
- IBM Cloud services using IAM authentication
- Other enterprise platforms using long JWT tokens

## Current Status

The proxy solution works perfectly and is in production use. However, native support would be much better for the Tasklet community as it would:
- Eliminate need for proxy infrastructure
- Reduce latency
- Simplify configuration
- Improve security (fewer intermediaries)

## Questions

1. Is there a configuration option to increase header length limits?
2. Are there plans to support longer Authorization headers?
3. Could JWT token generation be added as an authentication type?
4. Would you consider adding IBM Watson as a pre-configured integration?

Thank you for developing Tasklet. The platform is excellent, and with this small enhancement, it could support many more enterprise integrations.

I'm happy to provide more technical details or help test any solutions.

Best regards,
Patrick Smith

---

**P.S.** The proxy solution is open-source and available for any Tasklet users facing similar issues with long JWT tokens. It can be deployed on Railway, Heroku, or any Node.js platform in minutes.