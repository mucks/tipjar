# 🐳 Docker Deployment Guide

Complete guide for deploying Tipjar using Docker and GitHub Actions to your server.

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Local Docker Testing](#local-docker-testing)
3. [Server Setup](#server-setup)
4. [GitHub Actions Setup](#github-actions-setup)
5. [Manual Deployment](#manual-deployment)
6. [Troubleshooting](#troubleshooting)

---

## ⚡ Quick Start

### Test Locally with Docker

```bash
# Build and run with docker-compose
docker-compose up --build

# Visit http://localhost:3000
```

### Deploy to Your Server

```bash
# Push to GitHub (main/master branch)
git add .
git commit -m "Deploy tipjar"
git push origin main

# GitHub Actions automatically:
# ✅ Builds Docker image
# ✅ Pushes to GitHub Container Registry
# ✅ Deploys to your server
```

---

## 🏠 Local Docker Testing

### Option 1: Using Docker Compose (Recommended)

```bash
# Build and start
docker-compose up --build

# Run in background
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Rebuild after changes
docker-compose up --build --force-recreate
```

### Option 2: Using Docker Directly

```bash
# Build image
cd client
docker build -t tipjar-client .

# Run container
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_SOLANA_NETWORK=https://api.devnet.solana.com \
  tipjar-client

# Visit http://localhost:3000
```

### Test Different Networks

```bash
# Devnet
NEXT_PUBLIC_SOLANA_NETWORK=https://api.devnet.solana.com docker-compose up

# Mainnet
NEXT_PUBLIC_SOLANA_NETWORK=https://api.mainnet-beta.solana.com docker-compose up

# Localhost (requires validator running on host)
NEXT_PUBLIC_SOLANA_NETWORK=http://host.docker.internal:8899 docker-compose up
```

---

## 🖥️ Server Setup

### Prerequisites

Your server needs:
- Docker installed
- Docker Compose installed
- SSH access
- Git (optional, for manual deployments)

### 1. Install Docker on Server

```bash
# SSH into your server
ssh user@your-server.com

# Install Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Add your user to docker group (optional, logout/login after)
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker compose version
```

### 2. Create Deployment Directory

```bash
# Create directory for the app
sudo mkdir -p /opt/tipjar
sudo chown $USER:$USER /opt/tipjar
cd /opt/tipjar

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  tipjar-client:
    image: ghcr.io/YOUR_GITHUB_USERNAME/rust-smart-contracts/tipjar-client:latest
    container_name: tipjar-web
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_SOLANA_NETWORK=${NEXT_PUBLIC_SOLANA_NETWORK:-https://api.devnet.solana.com}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:3000', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

# Replace YOUR_GITHUB_USERNAME with your actual GitHub username
```

### 3. Set Up Reverse Proxy (Optional but Recommended)

#### Using Nginx

```bash
# Install Nginx
sudo apt-get install nginx

# Create site configuration
sudo nano /etc/nginx/sites-available/tipjar

# Add this configuration:
```

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/tipjar /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Optional: Set up SSL with Let's Encrypt
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

---

## 🔧 GitHub Actions Setup

### 1. Fork/Clone Repository

```bash
# If you haven't already, push your tipjar to GitHub
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/rust-smart-contracts.git
git push -u origin main
```

### 2. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SERVER_HOST` | Your server IP or domain | `192.168.1.100` or `tipjar.example.com` |
| `SERVER_USER` | SSH username | `ubuntu` or `root` |
| `SERVER_SSH_KEY` | Private SSH key | Paste your SSH private key |
| `SERVER_PORT` | SSH port (optional) | `22` (default) |
| `DEPLOY_PATH` | Deployment directory | `/opt/tipjar` |
| `SOLANA_NETWORK` | Solana RPC URL | `https://api.devnet.solana.com` |
| `SERVER_URL` | Health check URL (optional) | `http://your-domain.com` |

### 3. Generate SSH Key for Deployment

```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_deploy

# Copy public key to server
ssh-copy-id -i ~/.ssh/github_deploy.pub user@your-server.com

# Or manually:
cat ~/.ssh/github_deploy.pub
# SSH to server and add to ~/.ssh/authorized_keys

# Copy PRIVATE key content to GitHub secret SERVER_SSH_KEY
cat ~/.ssh/github_deploy
```

### 4. Test the Workflow

```bash
# Make a change and push
git add .
git commit -m "Test deployment"
git push origin main

# Check GitHub Actions tab in your repository
# Watch the deployment progress
```

---

## 🚀 Manual Deployment

If you prefer to deploy manually without GitHub Actions:

### Deploy from Local Machine

```bash
# Build and tag image
cd /Users/mucks/Projects/rust-smart-contracts/tipjar
docker build -t tipjar-client:latest ./client

# Save image to tar
docker save tipjar-client:latest | gzip > tipjar-client.tar.gz

# Copy to server
scp tipjar-client.tar.gz user@your-server.com:/tmp/

# SSH to server
ssh user@your-server.com

# Load image
docker load < /tmp/tipjar-client.tar.gz

# Start container
cd /opt/tipjar
docker-compose up -d
```

### Deploy from Server (Pull from Registry)

```bash
# SSH to server
ssh user@your-server.com
cd /opt/tipjar

# Pull latest image
docker pull ghcr.io/YOUR_USERNAME/rust-smart-contracts/tipjar-client:latest

# Restart services
docker-compose down
docker-compose up -d

# Check logs
docker-compose logs -f
```

---

## 🔍 Monitoring & Maintenance

### View Logs

```bash
# Real-time logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100

# Specific service logs
docker logs tipjar-web
```

### Check Container Status

```bash
# List running containers
docker ps

# Check health status
docker inspect tipjar-web | grep -A 10 Health

# Container stats
docker stats tipjar-web
```

### Update Deployment

```bash
# Pull latest image
docker-compose pull

# Restart with new image
docker-compose up -d

# Or use GitHub Actions workflow_dispatch for manual trigger
```

### Backup & Restore

```bash
# Backup (not much to backup since it's stateless)
docker-compose down
tar -czf tipjar-backup-$(date +%Y%m%d).tar.gz /opt/tipjar

# Restore
tar -xzf tipjar-backup-YYYYMMDD.tar.gz -C /
cd /opt/tipjar
docker-compose up -d
```

---

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Check if port is in use
sudo lsof -i :3000

# Kill process if needed
sudo kill -9 $(sudo lsof -t -i:3000)

# Restart
docker-compose up -d
```

### Image Pull Fails

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Or use personal access token
# Go to GitHub → Settings → Developer settings → Personal access tokens
# Create token with read:packages permission
docker login ghcr.io -u YOUR_USERNAME
```

### Deployment Fails in GitHub Actions

```bash
# Check GitHub Actions logs
# Common issues:

# 1. SSH Key Problems
# - Make sure private key is in correct format
# - No passphrase on key
# - Public key added to server's authorized_keys

# 2. Server Connection
# - Check SERVER_HOST is correct
# - Check SERVER_PORT (default 22)
# - Firewall allows SSH from GitHub (or disable temporarily)

# 3. Docker Permission
# - User added to docker group on server
# - Or use sudo in deployment script
```

### Health Check Fails

```bash
# Test manually
curl http://localhost:3000

# Check container
docker exec tipjar-web node -e "console.log('OK')"

# View health status
docker inspect tipjar-web | grep -A 10 Health
```

### Network Issues

```bash
# Check if container can reach internet
docker exec tipjar-web ping -c 3 google.com

# Check if it can reach Solana RPC
docker exec tipjar-web curl -I https://api.devnet.solana.com

# Check environment variables
docker exec tipjar-web env | grep SOLANA
```

---

## 📊 Performance Optimization

### Enable Docker BuildKit

```bash
# Add to ~/.bashrc or ~/.zshrc
export DOCKER_BUILDKIT=1
```

### Multi-Stage Build Benefits

The Dockerfile uses multi-stage builds:
- **Stage 1 (deps)**: Install production dependencies only
- **Stage 2 (builder)**: Build the Next.js app
- **Stage 3 (runner)**: Minimal runtime image

Result: ~200MB final image vs ~1GB without optimization

### Caching

GitHub Actions uses layer caching:
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

This speeds up subsequent builds significantly.

---

## 🔐 Security Best Practices

### 1. Use Non-Root User

The Dockerfile creates and uses a non-root user:
```dockerfile
RUN adduser --system --uid 1001 nextjs
USER nextjs
```

### 2. Keep Images Updated

```bash
# Update base image regularly
docker pull node:18-alpine

# Rebuild
docker-compose build --no-cache
```

### 3. Environment Variables

Never commit secrets:
```bash
# Use .env file locally (gitignored)
echo "NEXT_PUBLIC_SOLANA_NETWORK=https://api.devnet.solana.com" > .env.local

# Use secrets in production (GitHub Actions, server env vars)
```

### 4. Firewall Configuration

```bash
# Only allow necessary ports
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

---

## 🎯 Production Checklist

Before deploying to production:

- [ ] Smart contract deployed to mainnet
- [ ] Environment variables configured (mainnet RPC)
- [ ] SSL/TLS certificate installed (HTTPS)
- [ ] Firewall configured
- [ ] Monitoring set up (optional: Prometheus, Grafana)
- [ ] Backup strategy in place
- [ ] Domain configured correctly
- [ ] Health checks passing
- [ ] Logs collection configured
- [ ] Update deployment tested on devnet first

---

## 📚 Additional Resources

### Docker
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### GitHub Actions
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Action](https://github.com/docker/build-push-action)
- [SSH Action](https://github.com/appleboy/ssh-action)

### Next.js
- [Next.js Docker](https://nextjs.org/docs/deployment#docker-image)
- [Standalone Output](https://nextjs.org/docs/advanced-features/output-file-tracing)

---

## 🎉 Summary

You now have:
- ✅ Optimized Docker image
- ✅ docker-compose for easy deployment
- ✅ GitHub Actions CI/CD pipeline
- ✅ Automatic deployments on push
- ✅ Health checks and monitoring
- ✅ Production-ready setup

**Push to GitHub and watch it deploy automatically! 🚀**

