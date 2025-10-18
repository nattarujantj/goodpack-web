#!/bin/bash

# Flutter Production Run Script
# This script runs Flutter with production environment variables

# Set environment variables for production
export API_BASE_URL="https://api.goodpack.app/api"
export API_HOST="api.goodpack.app"
export API_PORT="443"
export API_PROTOCOL="https"
export QR_BASE_URL="https://goodpack.app"
export QR_DOMAIN="goodpack.app"
export ENVIRONMENT="production"
export DEBUG_MODE="false"
export WEB_HOST="0.0.0.0"
export WEB_PORT="3000"
export PLACEHOLDER_IMAGE_URL="https://via.placeholder.com/400x300?text=Product+Image"

# Get the Flutter path
FLUTTER_PATH="/Users/nattaruja.b@lmwn.com/Desktop/personal-test/flutter/bin/flutter"

# Check if Flutter exists
if [ ! -f "$FLUTTER_PATH" ]; then
    echo "❌ Flutter not found at: $FLUTTER_PATH"
    echo "Please update the FLUTTER_PATH in this script"
    exit 1
fi

echo "🚀 Starting Flutter app in production mode..."
echo "📱 API URL: $API_BASE_URL"
echo "🌐 QR URL: $QR_BASE_URL"
echo "🔧 Environment: $ENVIRONMENT"

# Run Flutter with production environment
$FLUTTER_PATH run -d web-server --web-port=$WEB_PORT --web-hostname=$WEB_HOST
