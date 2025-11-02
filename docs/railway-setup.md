# Railway Setup - Generate Domain

Since the API token isn't working directly, here's how to get your Railway URL:

## Option 1: Via Railway Dashboard (Easiest)

1. **Go to your project dashboard:**
   https://railway.app/project/270595cf-7ade-4443-a715-8ae5619bc690

2. **Click on the `watsonx-proxy` service** (should show as running/green)

3. **Go to the Settings tab**

4. **In the Networking section:**
   - Click **"Generate Domain"** button
   - Railway will create a public URL like:
     ```
     https://watsonx-proxy-production-xxxx.up.railway.app
     ```

5. **Copy this URL** - This is what you'll use in Tasklet!

## Option 2: Via Railway CLI (if logged in)

```bash
# Login to Railway (opens browser)
railway login

# Navigate to project directory
cd /Users/patricksmith/Projects/candlefish-ai/watsonx-proxy

# Link to your project
railway link

# Generate domain
railway domain
```

## Test Your Domain

Once you have the URL, test it:

```bash
# Replace with your actual Railway URL
RAILWAY_URL="https://watsonx-proxy-production-xxxx.up.railway.app"

# Test health endpoint
curl $RAILWAY_URL/health

# Should return:
# {
#   "status": "healthy",
#   "message": "Watsonx proxy is running and authenticated",
#   "tokenValid": true,
#   "tokenExpiry": "2025-11-02T03:XX:XX.000Z"
# }
```

## Configure Tasklet

With your Railway URL:

1. **Create new Direct API Connection in Tasklet**

2. **Configure as:**
   - **Connection Name**: `IBM Watson Orchestrate`
   - **Base URL**: `https://watsonx-proxy-production-xxxx.up.railway.app`
   - **Authentication**: Select **"No Auth"** or **"None"**
   - **Allowed Methods**: Select all (GET, POST, PATCH, PUT, DELETE)

3. **Click Save** - Validation should pass!

## How It Works

```
Tasklet Request → Railway Proxy → Watsonx API
(No Auth)        (Handles JWT)    (Returns Data)
```

Your proxy handles all the complex JWT token management, so Tasklet just sees a simple API with no authentication required!

## Monitoring

- **View Logs**: https://railway.app/project/270595cf-7ade-4443-a715-8ae5619bc690/logs
- **Check Health**: Visit `https://your-railway-url.railway.app/health`
- **Token Status**: Proxy auto-refreshes tokens before expiry

## Success! 🎉

Once you have the Railway URL and configure it in Tasklet, you'll have a working connection to IBM Watson Orchestrate without any JWT validation issues!