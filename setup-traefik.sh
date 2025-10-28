#!/bin/bash

# Traefik + Tipjar Setup Script
# Simple, automatic Docker-based reverse proxy with SSL

set -e

echo "🚀 Traefik + Tipjar Setup"
echo "=========================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Configuration
DEPLOY_DIR="/opt/tipjar"
DOMAIN="tipjar.mucks.me"
TRAEFIK_DASHBOARD_DOMAIN="traefik.mucks.me"
EMAIL="admin@mucks.me"

print_info "This script will set up:"
echo "  • Traefik reverse proxy with automatic HTTPS"
echo "  • Tipjar application at https://$DOMAIN"
echo "  • Traefik dashboard at https://$TRAEFIK_DASHBOARD_DOMAIN"
echo ""

read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi
echo ""

# Step 1: Create deployment directory
print_info "Step 1: Creating deployment directory..."
sudo mkdir -p $DEPLOY_DIR
sudo chown $USER:$USER $DEPLOY_DIR
cd $DEPLOY_DIR
print_success "Directory created: $DEPLOY_DIR"
echo ""

# Step 2: Create Docker network
print_info "Step 2: Creating Docker network..."
if docker network ls | grep -q "web"; then
    print_warning "Network 'web' already exists"
else
    docker network create web
    print_success "Network 'web' created"
fi
echo ""

# Step 3: Create docker-compose.yml
print_info "Step 3: Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    ports:
      - "80:80"
      - "443:443"
    command:
      # API and Dashboard
      - "--api.dashboard=true"
      
      # Docker provider
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=web"
      
      # Entrypoints
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      
      # HTTP to HTTPS redirect
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      
      # Let's Encrypt
      - "--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      
      # Logging
      - "--log.level=INFO"
      - "--accesslog=true"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(\`${TRAEFIK_DOMAIN}\`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.routers.traefik.middlewares=traefik-auth"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_AUTH}"

  tipjar:
    image: ghcr.io/${GITHUB_USERNAME}/rust-smart-contracts/tipjar-client:latest
    container_name: tipjar-web
    restart: unless-stopped
    environment:
      - NEXT_PUBLIC_SOLANA_NETWORK=${SOLANA_NETWORK}
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.tipjar.rule=Host(\`${TIPJAR_DOMAIN}\`)"
      - "traefik.http.routers.tipjar.entrypoints=websecure"
      - "traefik.http.routers.tipjar.tls.certresolver=letsencrypt"
      - "traefik.http.services.tipjar.loadbalancer.server.port=3000"
      - "traefik.http.routers.tipjar.middlewares=tipjar-headers"
      - "traefik.http.middlewares.tipjar-headers.headers.customresponseheaders.X-Frame-Options=SAMEORIGIN"

networks:
  web:
    external: true
EOF

print_success "docker-compose.yml created"
echo ""

# Step 4: Create .env file
print_info "Step 4: Creating environment configuration..."

# Ask for GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME

# Generate htpasswd for Traefik dashboard
print_info "Creating admin password for Traefik dashboard..."
read -s -p "Enter admin password: " ADMIN_PASSWORD
echo ""
# Use htpasswd format (escape $ signs)
TRAEFIK_AUTH=$(docker run --rm httpd:alpine htpasswd -nb admin "$ADMIN_PASSWORD" | sed 's/\$/\$\$/g')

cat > .env << EOF
# GitHub Configuration
GITHUB_USERNAME=$GITHUB_USERNAME

# Domain Configuration
TIPJAR_DOMAIN=$DOMAIN
TRAEFIK_DOMAIN=$TRAEFIK_DASHBOARD_DOMAIN

# Let's Encrypt
ACME_EMAIL=$EMAIL

# Solana Network
SOLANA_NETWORK=https://api.devnet.solana.com

# Traefik Dashboard Auth (admin password hashed)
TRAEFIK_AUTH=$TRAEFIK_AUTH
EOF

print_success "Configuration created"
echo ""

# Step 5: Create letsencrypt directory with proper permissions
print_info "Step 5: Setting up Let's Encrypt storage..."
mkdir -p letsencrypt
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json
print_success "Let's Encrypt storage ready"
echo ""

# Step 6: Start services
print_info "Step 6: Starting services..."
print_warning "Make sure DNS is configured before starting!"
echo "  • $DOMAIN → Your server IP"
echo "  • $TRAEFIK_DASHBOARD_DOMAIN → Your server IP"
echo ""

read -p "DNS configured? Start services now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose up -d
    print_success "Services started!"
    echo ""
    
    print_info "Waiting for services to be ready..."
    sleep 10
    
    # Check status
    docker-compose ps
else
    print_info "Skipped starting services"
    print_info "When ready, run: cd $DEPLOY_DIR && docker-compose up -d"
fi
echo ""

# Summary
echo "========================================"
print_success "🎉 SETUP COMPLETE!"
echo "========================================"
echo ""
print_info "Your services:"
echo "  🎯 Tipjar:          https://$DOMAIN"
echo "  📊 Traefik Dashboard: https://$TRAEFIK_DASHBOARD_DOMAIN"
echo "     Username: admin"
echo "     Password: (the one you set)"
echo ""
print_info "Configuration files:"
echo "  • $DEPLOY_DIR/docker-compose.yml"
echo "  • $DEPLOY_DIR/.env"
echo "  • $DEPLOY_DIR/letsencrypt/acme.json"
echo ""
print_info "Useful commands:"
echo "  • View logs:        docker-compose logs -f"
echo "  • Restart:          docker-compose restart"
echo "  • Stop:             docker-compose down"
echo "  • Update tipjar:    docker-compose pull tipjar && docker-compose up -d"
echo ""
print_warning "SSL certificates will be requested automatically!"
print_info "Check logs: docker-compose logs traefik"
echo ""
print_success "Done! 🚀"

