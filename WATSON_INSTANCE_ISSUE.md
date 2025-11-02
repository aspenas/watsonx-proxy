# Watson Orchestrate Instance Configuration Issue

## Problem Discovered

We have a mismatch between:
1. **Instance Name**: `watsonx-candlefish` (your IBM instance)
2. **Instance ID in API Key**: `20251101-2338-1901-402d-f441a2b6b26b` (embedded in JWT token)

## Error Details

When using `watsonx-candlefish` as the instance ID:
```
401 Unauthorized: "Instance ID in the request does not match with the tenant-id in the Bearer token"
```

This means the API key is tied to instance ID `20251101-2338-1901-402d-f441a2b6b26b`, not to `watsonx-candlefish`.

## Current Situation

1. **API Key**: The API key we're using generates JWT tokens for instance `20251101-2338-1901-402d-f441a2b6b26b`
2. **Instance Issue**: That instance returns "Tenant not found" for all API endpoints
3. **Your Instance**: `watsonx-candlefish` exists but requires a different API key

## Solution Options

### Option 1: Get API Key for watsonx-candlefish
1. Log into IBM Cloud dashboard
2. Navigate to your `watsonx-candlefish` instance
3. Generate a new API key specifically for this instance
4. Update the proxy with the new API key

### Option 2: Verify Instance ID
The ID `20251101-2338-1901-402d-f441a2b6b26b` might actually be correct for `watsonx-candlefish`. Check:
1. IBM Cloud dashboard → Watson Orchestrate
2. Look for the instance ID (not just the name)
3. It might show something like:
   - Name: watsonx-candlefish
   - ID: 20251101-2338-1901-402d-f441a2b6b26b

### Option 3: Instance Not Configured
The instance might exist but not have:
- Any agents configured
- Skills enabled
- Proper activation/provisioning

## Current Proxy Status

- Using Instance ID: `20251101-2338-1901-402d-f441a2b6b26b`
- Authentication: ✅ Working
- API Response: ❌ "Tenant not found" for all endpoints

## Next Steps

1. **Check IBM Cloud Dashboard**:
   - Verify the actual instance ID for `watsonx-candlefish`
   - Check if the instance is fully provisioned
   - Look for any agents or skills configured

2. **Get Correct API Key**:
   - If instance ID is different, generate new API key
   - Update `WATSONX_API_KEY` in proxy

3. **Test Endpoints**:
   - Once correct configuration is in place
   - Agent endpoints should work