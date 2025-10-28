# GitHub Actions Deployment Fix

## Issues Found
1. ❌ `cd ***` failing - deployment directory doesn't exist
2. ❌ `docker-compose: command not found` - modern Docker uses `docker compose` (space, not hyphen)

## Quick Fix

Replace your current deployment script with this:

```bash
#!/bin/bash
set -e

# Configuration
DEPLOY_DIR="/home/mucks/tipjar"
IMAGE_NAME="ghcr.io/YOUR_USERNAME/tipjar/tipjar-client:latest"
NETWORK="${NEXT_PUBLIC_SOLANA_NETWORK:-https://api.devnet.solana.com}"

echo "🚀 Starting deployment..."

# Create deployment directory (fixes "No such file or directory" error)
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# Login to GitHub Container Registry
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  tipjar-client:
    image: ghcr.io/YOUR_USERNAME/tipjar/tipjar-client:latest
    container_name: tipjar-web
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_SOLANA_NETWORK=${NEXT_PUBLIC_SOLANA_NETWORK}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:3000', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

# Create .env file
echo "NEXT_PUBLIC_SOLANA_NETWORK=$NETWORK" > .env

# Pull latest image
echo "📦 Pulling latest image..."
docker pull "$IMAGE_NAME"

# Stop and remove old container
echo "🛑 Stopping old container..."
docker compose down || true

# Start new container (using "docker compose" not "docker-compose")
echo "🚀 Starting new container..."
docker compose up -d

# Clean up old images
echo "🧹 Cleaning up..."
docker image prune -af

# Show status
echo "📊 Container status:"
docker compose ps

echo "🎉 Deployment complete!"
```

## Key Changes

### 1. Create Directory First
```bash
# Before (fails if directory doesn't exist):
cd /home/mucks/tipjar

# After (creates directory if needed):
mkdir -p /home/mucks/tipjar
cd /home/mucks/tipjar
```

### 2. Use Modern Docker Compose
```bash
# Before (old command):
docker-compose up -d

# After (new command):
docker compose up -d
```

## GitHub Actions Configuration

Make sure your GitHub Actions secrets include:
- `SERVER_HOST` - Your server IP or domain
- `SERVER_USER` - SSH user (e.g., root or ubuntu)
- `SERVER_SSH_KEY` - Private SSH key
- `GITHUB_TOKEN` - GitHub personal access token (for pulling images)
- `NEXT_PUBLIC_SOLANA_NETWORK` - Solana network URL

## Testing Locally

Test the deployment script on your server:

```bash
# Copy the deploy.sh script to your server
scp deploy.sh user@your-server:/tmp/

# SSH into your server
ssh user@your-server

# Run the deployment
sudo bash /tmp/deploy.sh
```

## Troubleshooting

### If docker compose still not found:
```bash
# Check Docker Compose version
docker compose version

# If not found, install Docker Compose plugin:
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

### If permission denied:
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Check logs:
```bash
cd /home/mucks/tipjar
docker compose logs -f
```

