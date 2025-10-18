#!/bin/bash

# Flutter Mobile Run Script
# This script runs Flutter with network access for mobile devices

# Get local IP address
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

# Set environment variables for mobile access
export API_BASE_URL="http://$LOCAL_IP:8080/api"
export API_HOST="$LOCAL_IP"
export API_PORT="8080"
export API_PROTOCOL="http"
export QR_BASE_URL="https://goodpack.app"
export QR_DOMAIN="goodpack.app"
export ENVIRONMENT="development"
export DEBUG_MODE="true"
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

echo "🚀 Starting Flutter app for mobile access..."
echo "📱 Local IP: $LOCAL_IP"
echo "📱 API URL: $API_BASE_URL"
echo "🌐 QR URL: $QR_BASE_URL"
echo "🔧 Environment: $ENVIRONMENT"
echo ""
echo "📱 Access from mobile: http://$LOCAL_IP:$WEB_PORT"
echo "💻 Access from desktop: http://localhost:$WEB_PORT"

# Run Flutter with network access
$FLUTTER_PATH run -d web-server --web-port=$WEB_PORT --web-hostname=$WEB_HOST
