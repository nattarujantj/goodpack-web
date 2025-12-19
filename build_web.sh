#!/bin/bash

# Flutter Web Build Script
# Usage: ./build_web.sh [API_URL]
# Example: ./build_web.sh http://192.168.1.162:8080/api

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default API URL
DEFAULT_API_URL="http://localhost:8080/api"

# Get API URL from argument or use default
API_URL="${1:-$DEFAULT_API_URL}"

echo -e "${GREEN}🚀 Building Flutter Web...${NC}"
echo -e "${YELLOW}📡 API URL: $API_URL${NC}"

# Clean previous build
echo -e "${YELLOW}🧹 Cleaning previous build...${NC}"
flutter clean

# Get dependencies
echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get

# Build web with environment variable
echo -e "${YELLOW}🔨 Building web app...${NC}"
flutter build web --dart-define=API_BASE_URL="$API_URL"

echo -e "${GREEN}✅ Build complete!${NC}"
echo -e "${GREEN}📁 Output: build/web/${NC}"

