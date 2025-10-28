#!/bin/bash

# Tipjar Server Setup Script
# Run this on your server to set up the deployment environment
# Configured for nginx-proxy-manager

set -e

echo "🚀 Tipjar Server Setup Script"
echo "=============================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "\033[0;31m❌ $1${NC}"; }

# Configuration
DEPLOY_DIR="/opt/tipjar"
GITHUB_USERNAME="${1:-YOUR_GITHUB_USERNAME}"
DOMAIN="tipjar.mucks.me"

if [ "$GITHUB_USERNAME" = "YOUR_GITHUB_USERNAME" ]; then
    echo "Usage: ./server-setup.sh YOUR_GITHUB_USERNAME"
    echo ""
    echo "Example: ./server-setup.sh mucks"
    exit 1
fi

print_info "Setting up Tipjar deployment for GitHub user: $GITHUB_USERNAME"
print_info "Domain: $DOMAIN"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. It's recommended to run as a regular user."
fi

# Step 1: Verify Docker is installed
print_info "Step 1: Verifying Docker installation..."
if command -v docker &> /dev/null; then
    print_success "Docker is installed: $(docker --version)"
else
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi
echo ""

# Step 2: Verify Docker Compose is installed
print_info "Step 2: Verifying Docker Compose installation..."
if docker compose version &> /dev/null; then
    print_success "Docker Compose is installed: $(docker compose version)"
else
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
echo ""

# Step 3: Create deployment directory
print_info "Step 3: Creating deployment directory..."
sudo mkdir -p $DEPLOY_DIR
sudo chown $USER:$USER $DEPLOY_DIR
print_success "Deployment directory created: $DEPLOY_DIR"
echo ""

# Step 4: Detect nginx-proxy-manager network
print_info "Step 4: Detecting nginx-proxy-manager network..."
# Check for common NPM network names
NPM_NETWORK=$(docker network ls --format "{{.Name}}" | grep -E "proxied|npm|nginx-proxy-manager" | head -n 1)
if [ -z "$NPM_NETWORK" ]; then
    NPM_NETWORK="proxied"
    print_warning "No NPM network found, using default: $NPM_NETWORK"
    print_info "If this is incorrect, edit docker-compose.yml after setup"
else
    print_success "Found nginx-proxy-manager network: $NPM_NETWORK"
fi
echo ""

# Step 5: Create docker-compose.yml with nginx-proxy-manager support
print_info "Step 5: Creating docker-compose.yml..."
cat > $DEPLOY_DIR/docker-compose.yml << EOF
version: '3.8'

services:
  tipjar-client:
    image: ghcr.io/$GITHUB_USERNAME/rust-smart-contracts/tipjar-client:latest
    container_name: tipjar-web
    expose:
      - "3000"
    environment:
      - NEXT_PUBLIC_SOLANA_NETWORK=\${NEXT_PUBLIC_SOLANA_NETWORK:-https://api.devnet.solana.com}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:3000', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - ${NPM_NETWORK}

networks:
  ${NPM_NETWORK}:
    external: true
EOF

print_success "docker-compose.yml created"
print_info "Container will be accessible through nginx-proxy-manager"
echo ""

# Step 6: Set up environment file
print_info "Step 6: Creating environment configuration..."
cat > $DEPLOY_DIR/.env << EOF
# Solana Network Configuration
NEXT_PUBLIC_SOLANA_NETWORK=https://api.devnet.solana.com

# For mainnet, use:
# NEXT_PUBLIC_SOLANA_NETWORK=https://api.mainnet-beta.solana.com
EOF

print_success "Environment file created"
print_info "Edit $DEPLOY_DIR/.env to change network"
echo ""

# Summary
echo ""
echo "========================================"
print_success "🎉 SERVER SETUP COMPLETE!"
echo "========================================"
echo ""
print_info "Setup Summary:"
echo "  • Docker:           Verified ✅"
echo "  • Docker Compose:   Verified ✅"
echo "  • Deploy Directory: $DEPLOY_DIR"
echo "  • Configuration:    $DEPLOY_DIR/.env"
echo "  • Domain:           $DOMAIN"
echo "  • NPM Network:      $NPM_NETWORK"
echo ""
print_info "Next Steps:"
echo ""
echo "  1️⃣  Configure nginx-proxy-manager:"
echo "      • Open your nginx-proxy-manager web UI"
echo "      • Add new Proxy Host:"
echo "        - Domain:          $DOMAIN"
echo "        - Scheme:          http"
echo "        - Forward Host:    tipjar-web"
echo "        - Forward Port:    3000"
echo "        - Enable: Block Common Exploits"
echo "        - Enable: Websockets Support"
echo "      • SSL Tab:"
echo "        - Request new SSL Certificate (Let's Encrypt)"
echo "        - Force SSL: ON"
echo ""
echo "  2️⃣  Set up GitHub Actions secrets:"
echo "      SERVER_HOST:     $(hostname -I | awk '{print $1}') or $DOMAIN"
echo "      SERVER_USER:     $USER"
echo "      SERVER_SSH_KEY:  (your SSH private key)"
echo "      DEPLOY_PATH:     $DEPLOY_DIR"
echo "      SERVER_URL:      https://$DOMAIN"
echo ""
echo "  3️⃣  Generate SSH key for GitHub Actions:"
echo "      ssh-keygen -t ed25519 -C \"github-actions\" -f ~/.ssh/github_deploy"
echo "      cat ~/.ssh/github_deploy.pub >> ~/.ssh/authorized_keys"
echo "      cat ~/.ssh/github_deploy  # Copy this to GitHub secret"
echo ""
echo "  4️⃣  Push your code to GitHub:"
echo "      git push origin main"
echo ""
echo "  5️⃣  Or deploy manually:"
echo "      cd $DEPLOY_DIR"
echo "      docker-compose up -d"
echo ""
print_warning "Don't forget to add $DOMAIN to your DNS pointing to this server!"
echo ""
print_success "Your server is ready for Tipjar deployment! 🚀"

