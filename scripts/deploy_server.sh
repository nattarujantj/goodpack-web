#!/bin/bash

# Deploy Script for Ubuntu Server
# This script pulls latest code, builds, and restarts services
# Should be placed on the Ubuntu server

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration - adjust these paths as needed
WEB_PROJECT_DIR="/opt/goodpack-web"
SERVER_PROJECT_DIR="/opt/goodpack-server"
NGINX_WEB_DIR="/var/www/html"
API_URL="http://192.168.1.162:8080/api"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀 Goodpack Deployment Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Function to deploy Go Server
deploy_server() {
    echo -e "\n${YELLOW}📦 Deploying Go Server...${NC}"
    
    cd "$SERVER_PROJECT_DIR"
    
    # Pull latest code
    echo -e "${YELLOW}   Pulling latest code...${NC}"
    git fetch origin
    git reset --hard origin/master
    
    # Build
    echo -e "${YELLOW}   Building server...${NC}"
    go mod tidy
    go build -o server
    
    # Stop existing server
    echo -e "${YELLOW}   Stopping existing server...${NC}"
    pkill -f "./server" || true
    sleep 2
    
    # Start new server
    echo -e "${YELLOW}   Starting new server...${NC}"
    nohup ./server > server.log 2>&1 &
    sleep 3
    
    # Check if server is running
    if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Go Server is running${NC}"
    else
        echo -e "${RED}   ❌ Go Server failed to start${NC}"
        tail -20 server.log
        exit 1
    fi
}

# Function to deploy Flutter Web
deploy_web() {
    echo -e "\n${YELLOW}🌐 Deploying Flutter Web...${NC}"
    
    cd "$WEB_PROJECT_DIR"
    
    # Pull latest code
    echo -e "${YELLOW}   Pulling latest code...${NC}"
    git fetch origin
    git reset --hard origin/master
    
    # Build
    echo -e "${YELLOW}   Getting dependencies...${NC}"
    flutter pub get
    
    echo -e "${YELLOW}   Building web app...${NC}"
    flutter build web --dart-define=API_BASE_URL="$API_URL"
    
    # Deploy to nginx
    echo -e "${YELLOW}   Deploying to nginx...${NC}"
    sudo rm -rf "$NGINX_WEB_DIR"/*
    sudo cp -r build/web/* "$NGINX_WEB_DIR"/
    
    # Restart nginx
    echo -e "${YELLOW}   Restarting nginx...${NC}"
    sudo systemctl restart nginx
    
    echo -e "${GREEN}   ✅ Flutter Web deployed${NC}"
}

# Main deployment
echo -e "\n${YELLOW}What would you like to deploy?${NC}"
echo "1) Go Server only"
echo "2) Flutter Web only"
echo "3) Both (Full deployment)"
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        deploy_server
        ;;
    2)
        deploy_web
        ;;
    3)
        deploy_server
        deploy_web
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🌐 Web: http://192.168.1.162${NC}"
echo -e "${YELLOW}📡 API: http://192.168.1.162:8080/api${NC}"

