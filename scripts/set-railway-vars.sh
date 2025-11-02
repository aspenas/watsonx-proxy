#!/bin/bash

# Set Railway environment variables using GraphQL API

RAILWAY_TOKEN="9e946487-0eec-402d-ac2d-4e5d8c743c0c"
PROJECT_ID="270595cf-7ade-4443-a715-8ae5619bc690"

# Read API key from .env file
API_KEY=$(grep WATSONX_API_KEY .env | cut -d '=' -f2)
INSTANCE_ID=$(grep WATSONX_INSTANCE_ID .env | cut -d '=' -f2)

echo "Setting Railway environment variables..."
echo ""

# GraphQL endpoint
GRAPHQL_URL="https://backboard.railway.app/graphql/v2"

# Function to set a variable
set_railway_var() {
    local name=$1
    local value=$2

    echo "Setting $name..."

    response=$(curl -s -X POST "$GRAPHQL_URL" \
        -H "Authorization: Bearer $RAILWAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"query\": \"mutation { variableUpsert(input: { projectId: \\\"$PROJECT_ID\\\", environmentId: \\\"production\\\", serviceId: \\\"watsonx-proxy\\\", name: \\\"$name\\\", value: \\\"$value\\\" }) }\"
        }")

    if echo "$response" | grep -q "error"; then
        echo "❌ Failed to set $name"
        echo "Response: $response"
    else
        echo "✅ $name set successfully"
    fi
}

# Set each variable
set_railway_var "WATSONX_API_KEY" "$API_KEY"
set_railway_var "WATSONX_INSTANCE_ID" "$INSTANCE_ID"
set_railway_var "NODE_ENV" "production"
set_railway_var "PORT" "3000"

echo ""
echo "✅ Environment variables configured!"
echo ""
echo "Railway will automatically redeploy with the new variables."
echo "Check deployment at: https://railway.app/project/$PROJECT_ID"