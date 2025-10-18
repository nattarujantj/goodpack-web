#!/bin/bash

echo "🚀 Starting deployment process..."

# Clean and build
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🔨 Building web app..."
flutter build web

# Create zip file
echo "📦 Creating deployment package..."
rm -f flutter_app_web.zip
zip -r flutter_app_web.zip build/web/

echo "✅ Deployment package ready!"
echo "📁 File: flutter_app_web.zip"
echo "🌐 Upload this file to Netlify: https://netlify.com"
echo ""
echo "📋 Next steps:"
echo "1. Go to https://netlify.com"
echo "2. Drag flutter_app_web.zip to deploy area"
echo "3. Wait for upload to complete"
echo "4. Share the new link with friends!"
