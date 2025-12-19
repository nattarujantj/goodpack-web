#!/bin/bash

# Deploy Go Server Only
# Usage: ./deploy_go_server.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
SERVER_DIR="/opt/goodpack-server"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀 Deploying Go Server${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd "$SERVER_DIR"

# Pull latest code
echo -e "${YELLOW}📥 Pulling latest code...${NC}"
git fetch origin
git reset --hard origin/master

# Build
echo -e "${YELLOW}🔨 Building server...${NC}"
go mod tidy
go build -o server

# Restart server via systemd
echo -e "${YELLOW}🔄 Restarting server via systemd...${NC}"
sudo systemctl restart goodpack-server
sleep 3

# Health check
if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Go Server deployed successfully!${NC}"
    echo -e "${BLUE}📡 API: http://192.168.1.162:8080/api${NC}"
else
    echo -e "${RED}❌ Server health check failed${NC}"
    echo -e "${YELLOW}Last 20 lines of log:${NC}"
    sudo journalctl -u goodpack-server --no-pager -n 20
    exit 1
fi

