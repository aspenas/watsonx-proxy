# Railway Environment Variables Setup

## 🔐 Required Environment Variables

You need to set these environment variables in Railway to make the proxy work in production.

### Option 1: Using Railway Dashboard (Easiest)

1. Go to your Railway project: https://railway.app/project/270595cf-7ade-4443-a715-8ae5619bc690
2. Click on your service (watsonx-proxy)
3. Go to "Variables" tab
4. Add these variables:

```
WATSONX_API_KEY=<your-api-key-from-ibm>
WATSONX_INSTANCE_ID=20251101-2338-1901-402d-f441a2b6b26b
NODE_ENV=production
PORT=3000
```

5. Railway will automatically redeploy with the new variables

### Option 2: Using Railway CLI

If you have a Railway token:

```bash
# 1. Get your Railway token from: https://railway.app/account/tokens

# 2. Run the setup script:
./scripts/setup-railway-env.sh YOUR_RAILWAY_TOKEN_HERE

# OR manually:
export RAILWAY_TOKEN=YOUR_TOKEN_HERE
railway link --project 270595cf-7ade-4443-a715-8ae5619bc690
railway variables set WATSONX_API_KEY="<your-api-key-from-ibm>"
railway variables set WATSONX_INSTANCE_ID="20251101-2338-1901-402d-f441a2b6b26b"
railway variables set NODE_ENV="production"
railway variables set PORT="3000"
railway up --detach
```

### Option 3: Using Railway API

```bash
# Using curl with your Railway token
RAILWAY_TOKEN="YOUR_TOKEN_HERE"
PROJECT_ID="270595cf-7ade-4443-a715-8ae5619bc690"

# Set WATSONX_API_KEY
curl -X POST "https://backboard.railway.app/graphql/v2" \
  -H "Authorization: Bearer $RAILWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { variableUpsert(input: { projectId: \"'$PROJECT_ID'\", name: \"WATSONX_API_KEY\", value: \"<your-api-key-here>\" }) }"
  }'
```

## 🔍 Verify Setup

After setting the variables, verify the deployment:

```bash
# Test the production endpoint
curl https://watsonx-proxy-production.up.railway.app/health

# Expected response:
{
  "status": "healthy",
  "message": "Watsonx proxy is running and authenticated",
  "tokenValid": true,
  "instance": "20251101-2338-1901-402d-f441a2b6b26b"
}
```

## ⚠️ Important Security Notes

1. **Never commit API keys to git** - Always use environment variables
2. **Use Railway's environment variables** for production
3. **Keep `.env` file local only** and in `.gitignore`
4. **Rotate API keys regularly** if compromised

## 🚨 If Railway Shows Errors

If the deployment fails after setting variables:

1. Check the deploy logs in Railway dashboard
2. Ensure all required variables are set
3. The app will exit with error if `WATSONX_API_KEY` is missing
4. Verify the API key is still valid with IBM

## 📝 Current Status

- ✅ Code updated to use environment variables
- ✅ Security fix deployed (no hardcoded keys)
- ⚠️ Railway needs environment variables set
- ✅ Local development uses .env file