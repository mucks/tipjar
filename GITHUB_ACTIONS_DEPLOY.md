# GitHub Actions Deployment - Complete Fix

## The Problem

Your GitHub Actions is failing with:
```
bash: line 2: cd: ***: No such file or directory
```

**Root Cause:** The deployment directory doesn't exist, and the script tries to `cd` into it before creating it.

## The Solution

Use the complete deployment script that **creates the directory first**.

---

## Option 1: Copy Script to Server (Recommended)

### Step 1: Copy the script to your server

```bash
scp github-deploy-script.sh mucks@your-server:/home/mucks/
```

### Step 2: Update Your GitHub Actions Workflow

In your `.github/workflows/deploy.yml`, use this deployment step:

```yaml
- name: Deploy to Server
  uses: appleboy/ssh-action@master
  env:
    IMAGE_NAME: ghcr.io/${{ github.repository_owner }}/tipjar/tipjar-client:latest
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GITHUB_ACTOR: ${{ github.actor }}
    NEXT_PUBLIC_SOLANA_NETWORK: ${{ secrets.NEXT_PUBLIC_SOLANA_NETWORK }}
    TIPJAR_DOMAIN: tipjar.mucks.me
  with:
    host: ${{ secrets.SERVER_HOST }}
    username: ${{ secrets.SERVER_USER }}
    key: ${{ secrets.SERVER_SSH_KEY }}
    envs: IMAGE_NAME,GITHUB_TOKEN,GITHUB_ACTOR,NEXT_PUBLIC_SOLANA_NETWORK,TIPJAR_DOMAIN
    script: |
      export IMAGE_NAME="${IMAGE_NAME}"
      export GITHUB_TOKEN="${GITHUB_TOKEN}"
      export GITHUB_ACTOR="${GITHUB_ACTOR}"
      export NEXT_PUBLIC_SOLANA_NETWORK="${NEXT_PUBLIC_SOLANA_NETWORK}"
      export TIPJAR_DOMAIN="${TIPJAR_DOMAIN}"
      bash /home/mucks/github-deploy-script.sh
```

---

## Option 2: Inline Script (No file copy needed)

Use this directly in your GitHub Actions workflow:

```yaml
- name: Deploy to Server
  uses: appleboy/ssh-action@master
  env:
    IMAGE_NAME: ghcr.io/${{ github.repository_owner }}/tipjar/tipjar-client:latest
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GITHUB_ACTOR: ${{ github.actor }}
    NEXT_PUBLIC_SOLANA_NETWORK: ${{ secrets.NEXT_PUBLIC_SOLANA_NETWORK }}
  with:
    host: ${{ secrets.SERVER_HOST }}
    username: mucks
    key: ${{ secrets.SERVER_SSH_KEY }}
    envs: IMAGE_NAME,GITHUB_TOKEN,GITHUB_ACTOR,NEXT_PUBLIC_SOLANA_NETWORK
    script: |
      #!/bin/bash
      set -e
      
      echo "🚀 Starting deployment..."
      
      # Configuration
      DEPLOY_DIR="/home/mucks/tipjar"
      TIPJAR_DOMAIN="tipjar.mucks.me"
      
      # CREATE DIRECTORY FIRST (This fixes the error!)
      mkdir -p "$DEPLOY_DIR"
      cd "$DEPLOY_DIR"
      
      # Login to registry
      echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR}" --password-stdin
      
      # Create docker-compose.yml
      cat > docker-compose.yml << 'COMPOSE_EOF'
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
            - "traefik.enable=true"
            - "traefik.http.routers.tipjar.rule=Host(`${TIPJAR_DOMAIN}`)"
            - "traefik.http.routers.tipjar.entrypoints=websecure"
            - "traefik.http.routers.tipjar.tls.certresolver=letsencrypt"
            - "traefik.http.services.tipjar.loadbalancer.server.port=3000"
            - "traefik.http.routers.tipjar.middlewares=tipjar-headers"
            - "traefik.http.middlewares.tipjar-headers.headers.customresponseheaders.X-Frame-Options=SAMEORIGIN"
            - "traefik.http.middlewares.tipjar-headers.headers.customresponseheaders.X-Content-Type-Options=nosniff"
          restart: unless-stopped
      networks:
        web:
          external: true
      COMPOSE_EOF
      
      # Create .env
      cat > .env << ENV_EOF
      IMAGE_NAME=${IMAGE_NAME}
      NEXT_PUBLIC_SOLANA_NETWORK=${NEXT_PUBLIC_SOLANA_NETWORK}
      TIPJAR_DOMAIN=${TIPJAR_DOMAIN}
      ENV_EOF
      
      # Deploy
      docker pull "${IMAGE_NAME}"
      docker compose down || true
      docker compose up -d
      docker image prune -af
      docker compose ps
      
      echo "🎉 Deployment complete!"
```

---

## Option 3: Minimal Fix (If you have your own script)

If you want to keep your existing script, just add this **ONE LINE** before the `cd` command:

```bash
# Before (FAILS):
cd /home/mucks/tipjar

# After (WORKS):
mkdir -p /home/mucks/tipjar && cd /home/mucks/tipjar
```

---

## Required GitHub Secrets

Make sure these secrets are set in your repository:

```
SERVER_HOST      = your-server-ip or domain
SERVER_USER      = mucks
SERVER_SSH_KEY   = your SSH private key
GITHUB_TOKEN     = ${{ secrets.GITHUB_TOKEN }} (automatic)
NEXT_PUBLIC_SOLANA_NETWORK = https://api.devnet.solana.com
```

---

## Key Changes That Fix The Error

### ❌ OLD (Broken):
```bash
# Navigate to deployment directory
cd /home/mucks/tipjar  # ← FAILS if directory doesn't exist
```

### ✅ NEW (Fixed):
```bash
# Create deployment directory
mkdir -p /home/mucks/tipjar  # ← Creates directory if it doesn't exist
cd /home/mucks/tipjar         # ← Now this works!
```

---

## Testing Locally

Test the script on your server before using it in GitHub Actions:

```bash
# SSH to your server
ssh mucks@your-server

# Run the deployment script
export IMAGE_NAME="ghcr.io/YOUR_USERNAME/tipjar/tipjar-client:latest"
export GITHUB_TOKEN="your-github-token"
export GITHUB_ACTOR="your-github-username"
export NEXT_PUBLIC_SOLANA_NETWORK="https://api.devnet.solana.com"

bash /home/mucks/github-deploy-script.sh
```

---

## Troubleshooting

### Error: "network web not found"
```bash
docker network create web
```

### Error: "docker compose: command not found"
```bash
# Install Docker Compose plugin
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

### Error: Permission denied
```bash
# Add user to docker group
sudo usermod -aG docker mucks
newgrp docker
```

### Verify deployment
```bash
cd /home/mucks/tipjar
docker compose logs -f
```

---

## Success Indicators

When deployment succeeds, you should see:

```
🚀 Starting Tipjar deployment...
📁 Creating deployment directory...
📂 Navigating to deployment directory...
🔐 Logging in to GitHub Container Registry...
Login Succeeded
📝 Creating docker-compose.yml...
⚙️  Creating .env file...
📦 Pulling latest image...
🛑 Stopping old container...
🚀 Starting new container...
🧹 Cleaning up old images...
📊 Container status:
NAME         IMAGE                                    STATUS
tipjar-web   ghcr.io/.../tipjar-client:latest        Up 2 seconds

========================================
🎉 Deployment complete!
========================================
Application: https://tipjar.mucks.me
========================================
```

Access your app at: **https://tipjar.mucks.me** 🎉

