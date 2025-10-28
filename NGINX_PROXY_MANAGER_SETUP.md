# 🔧 nginx-proxy-manager Setup Guide

Quick guide for deploying Tipjar with nginx-proxy-manager.

---

## ✅ Prerequisites

- Docker and Docker Compose installed
- nginx-proxy-manager already running
- Domain DNS configured (`tipjar.mucks.me` → your server IP)

---

## 🚀 Setup Steps

### Step 1: Run Server Setup Script

```bash
# Copy script to your server
scp server-setup.sh user@your-server.com:/tmp/

# SSH to server
ssh user@your-server.com

# Run setup (replace YOUR_GITHUB_USERNAME with your GitHub username)
bash /tmp/server-setup.sh YOUR_GITHUB_USERNAME
```

This will:
- ✅ Verify Docker & Docker Compose
- ✅ Create `/opt/tipjar` directory
- ✅ Generate docker-compose.yml with nginx-proxy-manager network
- ✅ Create environment configuration
- ✅ Show you nginx-proxy-manager configuration steps

---

### Step 2: Configure nginx-proxy-manager

1. **Open nginx-proxy-manager Web UI** (usually `http://your-server:81`)

2. **Add Proxy Host:**
   - Click "Hosts" → "Proxy Hosts" → "Add Proxy Host"

3. **Details Tab:**
   ```
   Domain Names:      tipjar.mucks.me
   Scheme:            http
   Forward Hostname:  tipjar-web
   Forward Port:      3000
   
   ☑ Block Common Exploits
   ☑ Websockets Support
   ```

4. **SSL Tab:**
   ```
   ☑ Force SSL
   ☑ HTTP/2 Support
   ☑ HSTS Enabled
   
   Request a new SSL Certificate:
   ☑ Let's Encrypt
   Email: your@email.com
   ☑ I Agree to the Let's Encrypt Terms of Service
   ```

5. **Click Save**

---

### Step 3: Deploy Container

```bash
# Navigate to deployment directory
cd /opt/tipjar

# Deploy (manually or wait for GitHub Actions)
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

---

### Step 4: Test

Visit: **https://tipjar.mucks.me**

You should see the Tipjar UI! 🎉

---

## 🔄 GitHub Actions Deployment

### Configure Secrets

Go to: **GitHub Repository → Settings → Secrets → Actions**

Add:
```
SERVER_HOST:       your-server-ip or tipjar.mucks.me
SERVER_USER:       your-username
SERVER_SSH_KEY:    your-ssh-private-key
DEPLOY_PATH:       /opt/tipjar
SOLANA_NETWORK:    https://api.devnet.solana.com
SERVER_URL:        https://tipjar.mucks.me
```

### Generate SSH Key

```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_deploy

# Copy public key to server
ssh-copy-id -i ~/.ssh/github_deploy.pub user@your-server.com

# Copy private key content to GitHub secret
cat ~/.ssh/github_deploy
```

### Deploy

```bash
git push origin main
```

GitHub Actions will automatically deploy! 🚀

---

## 🛠️ Troubleshooting

### Container Not Accessible

**Check if container is running:**
```bash
docker ps | grep tipjar
```

**Check logs:**
```bash
docker logs tipjar-web
```

**Check if it's on the right network:**
```bash
docker inspect tipjar-web | grep NetworkMode
```

### nginx-proxy-manager Can't Reach Container

**Option 1: Use container name**
```
Forward Hostname: tipjar-web
```

**Option 2: Use container IP**
```bash
# Get container IP
docker inspect tipjar-web | grep IPAddress

# Use that in nginx-proxy-manager
Forward Hostname: 172.x.x.x
```

**Option 3: Verify network**
```bash
# List networks
docker network ls

# Inspect nginx-proxy-manager network
docker network inspect nginx-proxy-manager_default

# Make sure tipjar-web is in the output
```

### SSL Certificate Fails

**Error: "DNS challenge failed"**
- Make sure `tipjar.mucks.me` DNS points to your server
- Wait a few minutes for DNS propagation
- Try again

**Error: "Rate limit"**
- Let's Encrypt has rate limits
- Wait an hour and try again
- Or use "Force SSL" without requesting new cert initially

### Port Already in Use

If you have port 3000 exposed and something else uses it:

```bash
# Edit docker-compose.yml to use expose instead
cd /opt/tipjar
nano docker-compose.yml

# Change:
ports:
  - "3000:3000"

# To:
expose:
  - "3000"

# Restart
docker-compose down
docker-compose up -d
```

---

## 🔧 Network Configuration

### Default Configuration (What the Script Creates)

```yaml
services:
  tipjar-client:
    expose:
      - "3000"
    networks:
      - nginx-proxy-manager_default

networks:
  nginx-proxy-manager_default:
    external: true
```

### If Your NPM Uses a Different Network

Edit `/opt/tipjar/docker-compose.yml`:

```yaml
networks:
  your-npm-network-name:
    external: true
```

To find your NPM network:
```bash
docker network ls | grep npm
```

---

## 📊 Verification Checklist

After setup:

- [ ] DNS resolves to your server
- [ ] nginx-proxy-manager proxy host created
- [ ] SSL certificate obtained
- [ ] Container running (`docker ps`)
- [ ] Container on NPM network
- [ ] Site accessible at https://tipjar.mucks.me
- [ ] QR code displays
- [ ] Wallet can connect
- [ ] GitHub Actions secrets configured

---

## 🎯 Quick Commands

```bash
# Check container status
docker ps | grep tipjar

# View logs
docker logs -f tipjar-web

# Restart container
cd /opt/tipjar && docker-compose restart

# Update deployment
cd /opt/tipjar
docker-compose pull
docker-compose up -d

# Check network
docker network inspect nginx-proxy-manager_default | grep tipjar

# Test from inside server
curl -I http://tipjar-web:3000
curl -I http://localhost  # Through NPM
```

---

## 🌐 Multiple Domains

Want to add more domains? In nginx-proxy-manager:

```
Domain Names:  tipjar.mucks.me, www.tipjar.mucks.me, tips.mucks.me
```

All will point to the same Tipjar!

---

## 🔒 Security Notes

### Recommended nginx-proxy-manager Settings

```
☑ Block Common Exploits
☑ Websockets Support
☑ Force SSL
☑ HTTP/2 Support
☑ HSTS Enabled
☐ Cache Assets (for better performance)
```

### Custom nginx Configuration

If needed, add in nginx-proxy-manager Advanced tab:

```nginx
# Rate limiting
limit_req_zone $binary_remote_addr zone=tipjar:10m rate=10r/s;
limit_req zone=tipjar burst=20;

# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

---

## 🎉 Success!

You should now have:
- ✅ Tipjar running in Docker
- ✅ Accessible at https://tipjar.mucks.me
- ✅ SSL certificate (Let's Encrypt)
- ✅ Automatic GitHub deployments
- ✅ nginx-proxy-manager managing traffic

**Visit https://tipjar.mucks.me and start receiving tips! 🎯**

---

## 📚 Related Docs

- `DOCKER_QUICKSTART.md` - Docker deployment basics
- `DOCKER_DEPLOYMENT.md` - Complete Docker guide
- `server-setup.sh` - Automated setup script

---

**Need help? Check the troubleshooting section above!** 🆘

