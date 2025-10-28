#!/bin/bash

# Tipjar Deployment Script
# This script is designed to be run by GitHub Actions or manually on the server

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Configuration
DEPLOY_DIR="${DEPLOY_DIR:-/home/mucks/tipjar}"
GITHUB_REGISTRY="${GITHUB_REGISTRY:-ghcr.io}"
IMAGE_NAME="${IMAGE_NAME:-tipjar/tipjar-client}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
NEXT_PUBLIC_SOLANA_NETWORK="${NEXT_PUBLIC_SOLANA_NETWORK:-https://api.devnet.solana.com}"
TIPJAR_DOMAIN="${TIPJAR_DOMAIN:-tipjar.mucks.me}"

print_info "Starting Tipjar deployment..."
echo ""

# Step 1: Create deployment directory if it doesn't exist
print_info "Step 1: Ensuring deployment directory exists..."
if [ ! -d "$DEPLOY_DIR" ]; then
    print_warning "Deployment directory doesn't exist. Creating: $DEPLOY_DIR"
    mkdir -p "$DEPLOY_DIR"
fi
print_success "Deployment directory ready: $DEPLOY_DIR"
echo ""

# Step 2: Create docker-compose.yml
print_info "Step 2: Creating docker-compose.yml..."
cat > "$DEPLOY_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  tipjar-client:
    image: ${IMAGE_FULL_NAME}
    container_name: tipjar-web
    expose:
      - "3000"
    environment:
      - NEXT_PUBLIC_SOLANA_NETWORK=${NEXT_PUBLIC_SOLANA_NETWORK}
    networks:
      - web
    labels:
      # Enable Traefik
      - "traefik.enable=true"
      
      # Router configuration
      - "traefik.http.routers.tipjar.rule=Host(`${TIPJAR_DOMAIN}`)"
      - "traefik.http.routers.tipjar.entrypoints=websecure"
      - "traefik.http.routers.tipjar.tls.certresolver=letsencrypt"
      
      # Service configuration
      - "traefik.http.services.tipjar.loadbalancer.server.port=3000"
      
      # Middleware - security headers
      - "traefik.http.routers.tipjar.middlewares=tipjar-headers"
      - "traefik.http.middlewares.tipjar-headers.headers.customresponseheaders.X-Frame-Options=SAMEORIGIN"
      - "traefik.http.middlewares.tipjar-headers.headers.customresponseheaders.X-Content-Type-Options=nosniff"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:3000', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  web:
    external: true
EOF

print_success "docker-compose.yml created"
echo ""

# Step 3: Create .env file
print_info "Step 3: Creating .env file..."
cat > "$DEPLOY_DIR/.env" << EOF
IMAGE_FULL_NAME=${GITHUB_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
NEXT_PUBLIC_SOLANA_NETWORK=${NEXT_PUBLIC_SOLANA_NETWORK}
TIPJAR_DOMAIN=${TIPJAR_DOMAIN}
EOF

print_success ".env file created"
echo ""

# Step 4: Pull latest image
print_info "Step 4: Pulling latest image..."
docker pull "${GITHUB_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
print_success "Image pulled successfully"
echo ""

# Step 5: Stop and remove old container
print_info "Step 5: Stopping old container..."
cd "$DEPLOY_DIR"
docker compose down || print_warning "No existing container to stop"
echo ""

# Step 6: Start new container
print_info "Step 6: Starting new container..."
docker compose up -d
print_success "Container started"
echo ""

# Step 7: Clean up old images
print_info "Step 7: Cleaning up old images..."
docker image prune -af
print_success "Cleanup complete"
echo ""

# Step 8: Show status
print_info "Step 8: Checking container status..."
docker compose ps
echo ""

# Summary
echo "========================================"
print_success "🎉 DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
print_info "Deployment Summary:"
echo "  • Directory:  $DEPLOY_DIR"
echo "  • Image:      ${GITHUB_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
echo "  • Network:    ${NEXT_PUBLIC_SOLANA_NETWORK}"
echo "  • Domain:     https://${TIPJAR_DOMAIN}"
echo "  • Container:  tipjar-web"
echo ""
print_info "Application should be accessible at:"
echo "  https://${TIPJAR_DOMAIN}"
echo ""
print_info "Check logs with:"
echo "  cd $DEPLOY_DIR && docker compose logs -f"
echo ""
print_warning "Make sure Traefik is running and the 'web' network exists!"
echo ""

