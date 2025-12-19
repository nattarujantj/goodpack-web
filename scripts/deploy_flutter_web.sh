#!/bin/bash

# Deploy Flutter Web Only
# Usage: ./deploy_flutter_web.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
WEB_DIR="/opt/goodpack-web"
NGINX_DIR="/var/www/html"
API_URL="http://192.168.1.162:8080/api"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🌐 Deploying Flutter Web${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd "$WEB_DIR"

# Pull latest code
echo -e "${YELLOW}📥 Pulling latest code...${NC}"
git fetch origin
git reset --hard origin/master

# Build
echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get

echo -e "${YELLOW}🔨 Building web app...${NC}"
flutter build web --dart-define=API_BASE_URL="$API_URL"

# Deploy to nginx
echo -e "${YELLOW}🚀 Deploying to nginx...${NC}"
sudo rm -rf "$NGINX_DIR"/*
sudo cp -r build/web/* "$NGINX_DIR"/
sudo systemctl restart nginx

echo -e "${GREEN}✅ Flutter Web deployed successfully!${NC}"
echo -e "${BLUE}🌐 Web: http://192.168.1.162${NC}"

