#!/bin/bash

# Run Flutter Web locally with remote API server
# Usage: ./run_local_with_remote_api.sh [API_URL]
# Example: ./run_local_with_remote_api.sh http://192.168.1.162:8080/api

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default API URL - Ubuntu Server
DEFAULT_API_URL="http://192.168.1.162:8080/api"

# Get API URL from argument or use default
API_URL="${1:-$DEFAULT_API_URL}"

# Web server settings
WEB_HOST="localhost"
WEB_PORT="3000"

echo -e "${GREEN}🚀 Starting Flutter Web with Remote API...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📡 API URL: $API_URL${NC}"
echo -e "${YELLOW}🌐 Web URL: http://$WEB_HOST:$WEB_PORT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if API server is reachable
echo -e "${YELLOW}🔍 Checking API server...${NC}"
if curl -s --connect-timeout 5 "${API_URL}/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API server is reachable${NC}"
else
    echo -e "${RED}⚠️  Warning: API server may not be reachable at $API_URL${NC}"
    echo -e "${YELLOW}   Make sure the Go server is running on Ubuntu${NC}"
    read -p "   Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Run Flutter with dart-define
flutter run -d chrome \
    --dart-define=API_BASE_URL="$API_URL" \
    --web-port=$WEB_PORT \
    --web-hostname=$WEB_HOST

