#!/bin/bash

# Script to start Watsonx proxy in a new terminal window

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create a temporary script to run in the new terminal
cat > /tmp/start-watsonx-proxy-terminal.sh << 'EOF'
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Watsonx Proxy Server - Terminal${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Navigate to the watsonx-proxy directory
cd /Users/patricksmith/Projects/candlefish-ai/watsonx-proxy

echo -e "${YELLOW}📁 Directory:${NC} $(pwd)"
echo -e "${YELLOW}🚀 Starting Watsonx Proxy Server...${NC}"
echo ""

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    npm install
    echo ""
fi

# Start the server
echo -e "${GREEN}✅ Starting server on port 3000...${NC}"
echo -e "${GREEN}🌐 Local URL: http://localhost:3000${NC}"
echo -e "${GREEN}🔗 Production URL: https://watsonx-proxy-production.up.railway.app${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""
echo "=========================================="
echo ""

# Run the server
npm start

# Keep terminal open after server stops
echo ""
echo -e "${YELLOW}Server stopped. Press any key to close this terminal...${NC}"
read -n 1
EOF

chmod +x /tmp/start-watsonx-proxy-terminal.sh

# Detect the operating system and open in appropriate terminal
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Starting Watsonx proxy in new Terminal window..."

    # Use AppleScript to open Terminal and run the script
    osascript << EOD
tell application "Terminal"
    activate
    set newWindow to do script "bash /tmp/start-watsonx-proxy-terminal.sh"
    set current settings of newWindow to settings set "Pro"
    set custom title of front window to "Watsonx Proxy Server"
end tell
EOD

    echo "✅ New Terminal window opened with Watsonx proxy"
    echo ""
    echo "The server is starting in the new terminal window."
    echo "Look for the window titled 'Watsonx Proxy Server'"

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    echo "Starting Watsonx proxy in new terminal..."

    # Try different terminal emulators
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal --title="Watsonx Proxy Server" -- bash /tmp/start-watsonx-proxy-terminal.sh
    elif command -v xterm &> /dev/null; then
        xterm -title "Watsonx Proxy Server" -e bash /tmp/start-watsonx-proxy-terminal.sh &
    elif command -v konsole &> /dev/null; then
        konsole --title "Watsonx Proxy Server" -e bash /tmp/start-watsonx-proxy-terminal.sh &
    else
        echo "No supported terminal emulator found. Please run manually:"
        echo "cd /Users/patricksmith/Projects/candlefish-ai/watsonx-proxy && npm start"
        exit 1
    fi

    echo "✅ New terminal window opened with Watsonx proxy"

else
    echo "Unsupported operating system: $OSTYPE"
    echo "Please run manually in a new terminal:"
    echo "cd /Users/patricksmith/Projects/candlefish-ai/watsonx-proxy && npm start"
    exit 1
fi

echo ""
echo "=========================================="
echo "Watsonx Proxy Status:"
echo "=========================================="
echo "• New terminal window: OPENED ✅"
echo "• Server starting on: http://localhost:3000"
echo "• Production URL: https://watsonx-proxy-production.up.railway.app"
echo ""
echo "You can now:"
echo "1. Check the new terminal window for server logs"
echo "2. Test the server: curl http://localhost:3000/health"
echo "3. Configure Tasklet with the URLs above"
echo "=========================================="