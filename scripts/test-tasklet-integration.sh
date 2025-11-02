#!/bin/bash

# Watsonx Proxy Integration Test for Tasklet
# Tests both local and production deployments

echo "=========================================="
echo "Watsonx Proxy Integration Test"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test endpoints
LOCAL_URL="http://localhost:3000"
PROD_URL="https://watsonx-proxy-production.up.railway.app"

# Function to test endpoint
test_endpoint() {
    local url=$1
    local endpoint=$2
    local description=$3

    echo -n "Testing $description: "

    response=$(curl -s -w "\n%{http_code}" "$url$endpoint")
    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓${NC} HTTP $http_code"

        # Check if response is JSON and contains expected fields
        if echo "$body" | jq . > /dev/null 2>&1; then
            if echo "$body" | jq -e '.status' > /dev/null 2>&1; then
                status=$(echo "$body" | jq -r '.status')
                echo "  Status: $status"
            fi
            if echo "$body" | jq -e '.tokenValid' > /dev/null 2>&1; then
                tokenValid=$(echo "$body" | jq -r '.tokenValid')
                echo "  Token Valid: $tokenValid"
            fi
            if echo "$body" | jq -e '.message' > /dev/null 2>&1; then
                message=$(echo "$body" | jq -r '.message')
                echo "  Message: $message"
            fi
        fi
    else
        echo -e "${RED}✗${NC} HTTP $http_code"
        if [ -n "$body" ]; then
            echo "  Response: $body"
        fi
    fi
    echo ""
}

# Test Watsonx API endpoints through proxy
test_watsonx_api() {
    local url=$1
    local name=$2

    echo -e "${YELLOW}Testing Watsonx API through $name proxy:${NC}"

    # Test a simple API endpoint
    echo -n "Testing API endpoint (/v1/skills): "
    response=$(curl -s -w "\n%{http_code}" -X GET "$url/v1/skills" -H "Accept: application/json")
    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d' | head -c 200) # Limit output

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓${NC} HTTP $http_code (Proxy working, forwarding requests)"
    elif [ "$http_code" = "404" ]; then
        echo -e "${YELLOW}⚠${NC} HTTP $http_code (Proxy working, but endpoint not found)"
    else
        echo -e "${RED}✗${NC} HTTP $http_code"
    fi

    # Show partial response
    if [ -n "$body" ]; then
        echo "  Response preview: ${body}..."
    fi
    echo ""
}

# Check if local server is running
check_local_server() {
    echo -e "${YELLOW}Checking Local Server:${NC}"
    if curl -s -f -o /dev/null "$LOCAL_URL"; then
        echo -e "${GREEN}✓${NC} Local server is running on port 3000"
        return 0
    else
        echo -e "${RED}✗${NC} Local server is not running"
        echo "  Start it with: npm start"
        return 1
    fi
    echo ""
}

# Main tests
echo "=========================================="
echo "1. LOCAL DEPLOYMENT TEST"
echo "=========================================="
echo ""

if check_local_server; then
    test_endpoint "$LOCAL_URL" "/" "Service Info"
    test_endpoint "$LOCAL_URL" "/health" "Health Check"
    test_watsonx_api "$LOCAL_URL" "Local"
fi

echo "=========================================="
echo "2. PRODUCTION DEPLOYMENT TEST (Railway)"
echo "=========================================="
echo ""

test_endpoint "$PROD_URL" "/" "Service Info"
test_endpoint "$PROD_URL" "/health" "Health Check"
test_watsonx_api "$PROD_URL" "Production"

echo "=========================================="
echo "3. TASKLET CONFIGURATION"
echo "=========================================="
echo ""
echo "Configure Tasklet with these settings:"
echo ""
echo -e "${GREEN}For Production (Recommended):${NC}"
echo "  Connection Name: IBM Watson Orchestrate"
echo "  Base URL: $PROD_URL"
echo "  Authentication: None / No Auth"
echo "  Allowed Methods: GET, POST, PATCH, PUT, DELETE"
echo ""
echo -e "${YELLOW}For Local Development:${NC}"
echo "  Connection Name: IBM Watson Orchestrate (Local)"
echo "  Base URL: $LOCAL_URL"
echo "  Authentication: None / No Auth"
echo "  Allowed Methods: GET, POST, PATCH, PUT, DELETE"
echo ""

echo "=========================================="
echo "4. API USAGE IN TASKLET"
echo "=========================================="
echo ""
echo "Once configured, you can use these endpoints in Tasklet:"
echo "  • GET /v1/skills - List available skills"
echo "  • POST /v1/threads - Create conversation thread"
echo "  • POST /v1/completions - Get AI completions"
echo "  • GET /health - Check service health"
echo ""
echo "The proxy automatically handles:"
echo "  ✓ JWT token generation from IBM IAM"
echo "  ✓ Token caching (5-minute refresh buffer)"
echo "  ✓ Bearer token injection in headers"
echo "  ✓ Error handling and retries"
echo ""

echo "=========================================="
echo "Test completed!"
echo "==========================================
"