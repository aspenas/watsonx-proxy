# Deploy Watsonx Proxy to Railway

## Option 1: Deploy via GitHub (Recommended)

### Step 1: Push to GitHub

```bash
cd /Users/patricksmith/Projects/candlefish-ai/watsonx-proxy

# Create new GitHub repo (or use existing)
gh repo create watsonx-proxy --public --source=. --remote=origin --push
```

Or manually:
1. Go to https://github.com/new
2. Create repo named `watsonx-proxy`
3. Push code:
```bash
git remote add origin https://github.com/YOUR_USERNAME/watsonx-proxy.git
git branch -M main
git push -u origin main
```

### Step 2: Deploy on Railway Dashboard

1. Go to https://railway.app/dashboard
2. Click **"New Project"**
3. Choose **"Deploy from GitHub repo"**
4. Select `watsonx-proxy` repository
5. Railway will auto-detect Node.js and start deployment

### Step 3: Set Environment Variables (REQUIRED)

In Railway dashboard, go to Variables tab and add:
```
WATSONX_API_KEY=<your-api-key-from-ibm>
WATSONX_INSTANCE_ID=20251101-2338-1901-402d-f441a2b6b26b
NODE_ENV=production
PORT=3000
```

**Important**: The WATSONX_API_KEY is required and must be obtained from IBM Watson

### Step 4: Get Your URL

1. Go to Settings tab
2. Under Domains, click **"Generate Domain"**
3. Your URL will be something like:
   ```
   https://watsonx-proxy-production-xxxx.up.railway.app
   ```

## Option 2: Deploy via Railway CLI

If you prefer using CLI:

```bash
# Login to Railway
railway login

# Navigate to proxy directory
cd /Users/patricksmith/Projects/candlefish-ai/watsonx-proxy

# Initialize and deploy
railway init --name watsonx-proxy
railway up

# Get the URL
railway domain
```

## Configure Tasklet

Once deployed, use these settings in Tasklet:

1. **Connection Name**: `IBM Watson Orchestrate`
2. **Base URL**: `https://watsonx-proxy-production-xxxx.up.railway.app`
3. **Authentication**: Select **"No Auth"** or **"None"**
4. **Allowed Methods**: Select all (GET, POST, PATCH, PUT, DELETE)

## Test the Deployment

```bash
# Test health endpoint
curl https://watsonx-proxy-production-xxxx.up.railway.app/health

# Should return:
# {
#   "status": "healthy",
#   "message": "Watsonx proxy is running and authenticated",
#   "tokenValid": true
# }
```

## Monitoring

- View logs: Railway Dashboard → Your Service → Logs
- Check metrics: Railway Dashboard → Your Service → Metrics
- Health endpoint: `https://your-url.railway.app/health`

## Benefits

✅ **No authentication issues** - Proxy handles JWT tokens
✅ **Always available** - Railway keeps it running 24/7
✅ **Auto-refresh** - Tokens refresh automatically
✅ **Simple for Tasklet** - Just use the Railway URL, no auth needed
✅ **Free tier** - Railway offers $5/month free credits