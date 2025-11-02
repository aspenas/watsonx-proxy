#!/bin/bash

# Script to set up Railway environment variables
# Usage: ./setup-railway-env.sh <RAILWAY_TOKEN>

set -e

echo "=========================================="
echo "Railway Environment Variables Setup"
echo "=========================================="
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "Installing Railway CLI..."
    npm install -g @railway/cli
fi

# Check if token is provided
if [ -z "$1" ]; then
    echo "❌ ERROR: Railway token not provided"
    echo ""
    echo "Usage: ./setup-railway-env.sh <RAILWAY_TOKEN>"
    echo ""
    echo "To get your Railway token:"
    echo "1. Go to https://railway.app/account/tokens"
    echo "2. Create a new token"
    echo "3. Copy and run: ./setup-railway-env.sh YOUR_TOKEN_HERE"
    exit 1
fi

RAILWAY_TOKEN=$1

echo "🔐 Using Railway token: ${RAILWAY_TOKEN:0:10}..."
export RAILWAY_TOKEN=$RAILWAY_TOKEN

# Link to project
echo "📎 Linking to Railway project..."
railway link --project 270595cf-7ade-4443-a715-8ae5619bc690

# Set environment variables
echo ""
echo "⚙️ Setting environment variables..."

# Read from .env file
if [ -f .env ]; then
    echo "📄 Reading from .env file..."

    # Set WATSONX_API_KEY
    API_KEY=$(grep WATSONX_API_KEY .env | cut -d '=' -f2)
    if [ ! -z "$API_KEY" ]; then
        railway variables set WATSONX_API_KEY="$API_KEY"
        echo "✅ WATSONX_API_KEY set"
    fi

    # Set WATSONX_INSTANCE_ID
    INSTANCE_ID=$(grep WATSONX_INSTANCE_ID .env | cut -d '=' -f2)
    if [ ! -z "$INSTANCE_ID" ]; then
        railway variables set WATSONX_INSTANCE_ID="$INSTANCE_ID"
        echo "✅ WATSONX_INSTANCE_ID set"
    fi
else
    echo "⚠️ .env file not found"
    echo ""
    echo "Please enter your WATSONX_API_KEY:"
    read -s API_KEY
    echo ""

    # Set variables with user input
    railway variables set WATSONX_API_KEY="$API_KEY"
    railway variables set WATSONX_INSTANCE_ID="20251101-2338-1901-402d-f441a2b6b26b"
    echo "✅ Variables set from user input"
fi

# Set NODE_ENV to production
railway variables set NODE_ENV="production"
railway variables set PORT="3000"
echo "✅ NODE_ENV=production"
echo "✅ PORT=3000"

echo ""
echo "🚀 Deploying changes..."
railway up --detach

echo ""
echo "=========================================="
echo "✅ Railway environment configured!"
echo "=========================================="
echo ""
echo "Variables set:"
echo "  • WATSONX_API_KEY"
echo "  • WATSONX_INSTANCE_ID"
echo "  • NODE_ENV=production"
echo "  • PORT=3000"
echo ""
echo "Deployment URL: https://watsonx-proxy-production.up.railway.app"
echo ""
echo "Test with:"
echo "  curl https://watsonx-proxy-production.up.railway.app/health"
echo ""