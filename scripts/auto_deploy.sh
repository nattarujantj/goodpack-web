#!/bin/bash

# Auto Deploy Script for Ubuntu Server
# This script is called by GitHub Actions via SSH
# Usage: ./auto_deploy.sh [web|server|all]

set -e

# Configuration
WEB_PROJECT_DIR="/opt/goodpack-web"
SERVER_PROJECT_DIR="/opt/goodpack-server"
NGINX_WEB_DIR="/var/www/html"
API_URL="http://192.168.1.162:8080/api"
LOG_FILE="/var/log/goodpack-deploy.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

deploy_server() {
    log "🚀 Deploying Go Server..."
    
    cd "$SERVER_PROJECT_DIR"
    
    log "   Pulling latest code..."
    git fetch origin
    git reset --hard origin/master
    
    log "   Building server..."
    go mod tidy
    go build -o server
    
    log "   Restarting server..."
    pkill -f "./server" || true
    sleep 2
    nohup ./server > server.log 2>&1 &
    sleep 3
    
    if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
        log "   ✅ Go Server deployed successfully"
    else
        log "   ❌ Go Server failed to start"
        exit 1
    fi
}

deploy_web() {
    log "🌐 Deploying Flutter Web..."
    
    cd "$WEB_PROJECT_DIR"
    
    log "   Pulling latest code..."
    git fetch origin
    git reset --hard origin/master
    
    log "   Building web app..."
    flutter pub get
    flutter build web --dart-define=API_BASE_URL="$API_URL"
    
    log "   Deploying to nginx..."
    sudo rm -rf "$NGINX_WEB_DIR"/*
    sudo cp -r build/web/* "$NGINX_WEB_DIR"/
    sudo systemctl restart nginx
    
    log "   ✅ Flutter Web deployed successfully"
}

# Main
DEPLOY_TARGET="${1:-all}"

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Starting deployment: $DEPLOY_TARGET"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

case $DEPLOY_TARGET in
    server)
        deploy_server
        ;;
    web)
        deploy_web
        ;;
    all)
        deploy_server
        deploy_web
        ;;
    *)
        log "Invalid target: $DEPLOY_TARGET"
        log "Usage: $0 [web|server|all]"
        exit 1
        ;;
esac

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "✅ Deployment complete!"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

