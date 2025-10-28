#!/bin/bash
set -e

echo "🚀 Starting Tipjar deployment..."

# Configuration
DEPLOY_DIR="/home/mucks/tipjar"
TIPJAR_DOMAIN="${TIPJAR_DOMAIN:-tipjar.mucks.me}"
NEXT_PUBLIC_SOLANA_NETWORK="${NEXT_PUBLIC_SOLANA_NETWORK:-https://api.devnet.solana.com}"

# Step 1: Create deployment directory (FIX: This was missing!)
echo "📁 Creating deployment directory..."
mkdir -p "$DEPLOY_DIR"

# Step 2: Navigate to deployment directory
echo "📂 Navigating to deployment directory..."
cd "$DEPLOY_DIR"

# Step 3: Login to GitHub Container Registry
echo "🔐 Logging in to GitHub Container Registry..."
echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR}" --password-stdin

# Step 4: Create docker-compose.yml
echo "📝 Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  tipjar-client:
    image: ${IMAGE_NAME}
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

# Step 5: Create .env file
echo "⚙️  Creating .env file..."
cat > .env << EOF
IMAGE_NAME=${IMAGE_NAME}
NEXT_PUBLIC_SOLANA_NETWORK=${NEXT_PUBLIC_SOLANA_NETWORK}
TIPJAR_DOMAIN=${TIPJAR_DOMAIN}
EOF

# Step 6: Pull the latest image
echo "📦 Pulling latest image..."
docker pull "${IMAGE_NAME}"

# Step 7: Stop and remove old container
echo "🛑 Stopping old container..."
docker compose down || echo "No existing container to stop"

# Step 8: Start new container
echo "🚀 Starting new container..."
docker compose up -d

# Step 9: Clean up old images
echo "🧹 Cleaning up old images..."
docker image prune -af

# Step 10: Show status
echo "📊 Container status:"
docker compose ps

echo ""
echo "========================================"
echo "🎉 Deployment complete!"
echo "========================================"
echo "Application: https://${TIPJAR_DOMAIN}"
echo "Directory: ${DEPLOY_DIR}"
echo "========================================"

