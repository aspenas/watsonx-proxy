#!/bin/bash

echo "=========================================="
echo "Railway Domain Setup for Watsonx Proxy"
echo "=========================================="
echo ""

# Your Railway details
RAILWAY_TOKEN="25098cd9-c474-4f34-873c-fa181ccd5dc3"
PROJECT_ID="270595cf-7ade-4443-a715-8ae5619bc690"

echo "Project ID: $PROJECT_ID"
echo ""

# Function to make GraphQL queries to Railway
railway_query() {
    local query="$1"
    curl -s -X POST https://backboard.railway.app/graphql \
        -H "Authorization: Bearer $RAILWAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$query\"}"
}

# Get service details
echo "Fetching service details..."
QUERY='query { project(id: \"'$PROJECT_ID'\") {
    id
    name
    services {
        edges {
            node {
                id
                name
            }
        }
    }
    deployments(first: 1) {
        edges {
            node {
                id
                status
                staticUrl
            }
        }
    }
}}'

RESPONSE=$(railway_query "$QUERY")

if [ -z "$RESPONSE" ]; then
    echo "Error: Could not connect to Railway API"
    echo "Please check your token and try again"
    exit 1
fi

echo "Response from Railway:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

# Parse the response to get service ID
SERVICE_ID=$(echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'data' in data and 'project' in data['data']:
    services = data['data']['project'].get('services', {}).get('edges', [])
    if services:
        print(services[0]['node']['id'])
" 2>/dev/null)

if [ -z "$SERVICE_ID" ]; then
    echo ""
    echo "Could not find service ID. The service might still be deploying."
    echo "Please wait a moment and try again, or check the Railway dashboard."
else
    echo ""
    echo "Service ID found: $SERVICE_ID"
    echo ""
    echo "To generate a domain:"
    echo "1. Go to: https://railway.app/project/$PROJECT_ID"
    echo "2. Click on your service"
    echo "3. Go to Settings tab"
    echo "4. Under Networking, click 'Generate Domain'"
fi

echo ""
echo "=========================================="
echo "Once you have the Railway URL, use it in Tasklet:"
echo ""
echo "Connection Name: IBM Watson Orchestrate"
echo "Base URL: https://YOUR-DOMAIN.railway.app"
echo "Authentication: None"
echo "=========================================="