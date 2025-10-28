# 🚀 Docker Deployment - Quick Start

## 3-Step Deployment

### Step 1: Set Up Your Server

```bash
# Copy setup script to your server
scp server-setup.sh user@your-server.com:/tmp/

# SSH to server and run setup
ssh user@your-server.com
bash /tmp/server-setup.sh YOUR_GITHUB_USERNAME
```

The script installs Docker, creates deployment directories, and sets up configurations.

---

### Step 2: Configure GitHub Secrets

Go to: GitHub Repository → Settings → Secrets → Actions

Add these secrets:

| Secret | Value | Example |
|--------|-------|---------|
| `SERVER_HOST` | Your server IP | `192.168.1.100` |
| `SERVER_USER` | SSH username | `ubuntu` |
| `SERVER_SSH_KEY` | SSH private key | (see below) |
| `DEPLOY_PATH` | Deploy directory | `/opt/tipjar` |
| `SOLANA_NETWORK` | Solana RPC URL | `https://api.devnet.solana.com` |

**Generate SSH key:**
```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_deploy

# Copy public key to server
ssh-copy-id -i ~/.ssh/github_deploy.pub user@your-server.com

# Copy PRIVATE key content for GitHub secret
cat ~/.ssh/github_deploy
```

---

### Step 3: Deploy!

```bash
# Push to GitHub
git add .
git commit -m "Deploy to server"
git push origin main

# GitHub Actions automatically deploys! 🎉
```

---

## Manual Testing

### Test Locally First

```bash
# Build and run locally
docker-compose up --build

# Visit http://localhost:3000
```

### Test on Server

```bash
# SSH to server
ssh user@your-server.com

# Navigate to deployment directory
cd /opt/tipjar

# Start the app
docker-compose up -d

# Check logs
docker-compose logs -f

# Check status
docker-compose ps

# Visit http://your-server-ip:3000
```

---

## Common Commands

```bash
# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Stop
docker-compose down

# Update
docker-compose pull && docker-compose up -d

# Check status
docker ps

# Shell into container
docker exec -it tipjar-web sh
```

---

## Troubleshooting

### Container won't start?
```bash
docker-compose logs
```

### Port 3000 in use?
```bash
sudo lsof -i :3000
sudo kill -9 $(sudo lsof -t -i:3000)
```

### Can't pull image?
```bash
# Login to GitHub Container Registry
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

### Deployment failed?
Check GitHub Actions logs in your repository.

---

## URLs After Deployment

- **Direct Access**: `http://your-server-ip:3000`
- **With Domain**: `http://your-domain.com` (if Nginx configured)
- **HTTPS**: `https://your-domain.com` (if SSL configured)

---

## Production Checklist

Before going live:

- [ ] Deploy smart contract to mainnet
- [ ] Set `SOLANA_NETWORK` to mainnet
- [ ] Configure domain name
- [ ] Set up SSL certificate
- [ ] Configure firewall
- [ ] Test all features

---

## Need Help?

See complete guide: `DOCKER_DEPLOYMENT.md`

---

**That's it! Your Tipjar is now deployed! 🎉**

