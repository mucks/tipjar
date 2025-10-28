# 🚀 Central Traefik + Tipjar Setup Guide

Complete guide for running one central Traefik instance with Tipjar and other services.

---

## 📋 Architecture

```
┌─────────────────────────────────────┐
│         Central Traefik             │
│    (One instance for all services)  │
│                                     │
│  - Automatic HTTPS                  │
│  - Certificate management           │
│  - Routing by domain                │
└──────────┬──────────────────────────┘
           │
    ┌──────┴──────┐
    │             │
┌───▼────┐   ┌───▼────┐   ┌─────────┐
│ Tipjar │   │  Blog  │   │   API   │
└────────┘   └────────┘   └─────────┘
```

---

## ⚡ Quick Setup

### Step 1: Set Up Central Traefik (Once)

```bash
# On your server, create traefik directory
mkdir -p /opt/traefik
cd /opt/traefik

# Copy traefik/docker-compose.yml to server
# (You can copy the file from this repo)

# Create environment file
cp env.example .env
nano .env  # Edit with your settings

# Create required directories
mkdir -p letsencrypt logs
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json

# Create network
docker network create web

# Start Traefik
docker-compose up -d

# Check logs
docker-compose logs -f
```

**Done!** Traefik is now running and ready for services. ✅

---

### Step 2: Deploy Tipjar (And Any Other Service)

```bash
# On your server, create tipjar directory
mkdir -p /opt/tipjar
cd /opt/tipjar

# Copy docker-compose.yml to server
# (The main one in the repo root)

# Create environment file
cat > .env << EOF
NEXT_PUBLIC_SOLANA_NETWORK=https://api.devnet.solana.com
TIPJAR_DOMAIN=tipjar.mucks.me
EOF

# Start Tipjar
docker-compose up -d

# Check logs
docker-compose logs -f
```

**That's it!** Tipjar is now live at https://tipjar.mucks.me ✅

---

## 📁 File Structure

### On Your Server

```
/opt/
├── traefik/                    # Central Traefik
│   ├── docker-compose.yml
│   ├── .env
│   ├── letsencrypt/
│   │   └── acme.json
│   └── logs/
│       ├── access.log
│       └── traefik.log
│
└── tipjar/                     # Tipjar service
    ├── docker-compose.yml
    └── .env
```

---

## 🔧 Configuration

### Traefik Configuration (`/opt/traefik/.env`)

```bash
# Copy from traefik/env.example

ACME_EMAIL=admin@mucks.me
TRAEFIK_DOMAIN=traefik.mucks.me
LOG_LEVEL=INFO

# Generate password hash:
# docker run --rm httpd:alpine htpasswd -nb admin yourpassword
TRAEFIK_BASIC_AUTH=admin:$$apr1$$...
```

### Tipjar Configuration (`/opt/tipjar/.env`)

```bash
# Solana Network
NEXT_PUBLIC_SOLANA_NETWORK=https://api.devnet.solana.com

# Domain
TIPJAR_DOMAIN=tipjar.mucks.me
```

---

## 🌐 DNS Configuration

Point these domains to your server IP:

```
traefik.mucks.me  → your-server-ip
tipjar.mucks.me   → your-server-ip
```

You can add more later for other services!

---

## 🎯 Adding More Services

Want to add another service? Super easy!

```bash
# Create a new directory
mkdir -p /opt/my-new-app
cd /opt/my-new-app

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  my-app:
    image: my-app:latest
    container_name: my-app
    restart: unless-stopped
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.mucks.me`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"

networks:
  web:
    external: true
EOF

# Start it
docker-compose up -d
```

**Boom!** New service with automatic HTTPS! ✨

---

## 🔍 Management

### View All Services

```bash
# Visit Traefik dashboard
https://traefik.mucks.me

# Or via Docker
docker ps
```

### View Logs

```bash
# Traefik logs
cd /opt/traefik
docker-compose logs -f

# Tipjar logs
cd /opt/tipjar
docker-compose logs -f

# Access logs
cd /opt/traefik
tail -f logs/access.log
```

### Restart Services

```bash
# Restart Traefik
cd /opt/traefik
docker-compose restart

# Restart Tipjar
cd /opt/tipjar
docker-compose restart
```

### Update Services

```bash
# Update Traefik
cd /opt/traefik
docker-compose pull
docker-compose up -d

# Update Tipjar
cd /opt/tipjar
docker-compose pull
docker-compose up -d
```

---

## 🔐 Security

### Generate Dashboard Password

```bash
# Generate password hash for Traefik dashboard
docker run --rm httpd:alpine htpasswd -nb admin yourpassword

# Copy output to /opt/traefik/.env
# Remember to escape $ as $$
```

### SSL Certificates

- **Automatic**: Let's Encrypt handles everything
- **Renewal**: Automatic (Traefik does it)
- **Storage**: `/opt/traefik/letsencrypt/acme.json`

### Firewall

```bash
# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp  # SSH

sudo ufw enable
```

---

## 📊 Monitoring

### Traefik Dashboard

**URL**: https://traefik.mucks.me

**Features**:
- View all services
- See routing rules
- Monitor requests
- Check SSL certificates
- View middleware

### Access Logs

```bash
cd /opt/traefik
tail -f logs/access.log
```

### Container Stats

```bash
docker stats
```

---

## 🐛 Troubleshooting

### SSL Certificate Not Working

```bash
# Check DNS
nslookup tipjar.mucks.me

# Check Traefik logs
cd /opt/traefik
docker-compose logs | grep -i error

# Check certificate file
ls -la letsencrypt/acme.json

# Verify port 80 is accessible
curl -I http://tipjar.mucks.me
```

### Service Not Accessible

```bash
# Check if service is running
docker ps

# Check if it's in the web network
docker network inspect web

# Check service labels
docker inspect tipjar-web | grep -A 20 Labels

# Restart both Traefik and the service
cd /opt/traefik && docker-compose restart
cd /opt/tipjar && docker-compose restart
```

### Dashboard Can't Login

```bash
# Verify password hash
cd /opt/traefik
cat .env | grep TRAEFIK_BASIC_AUTH

# Generate new password
docker run --rm httpd:alpine htpasswd -nb admin newpassword

# Update .env and restart
nano .env
docker-compose restart
```

---

## 🔄 GitHub Actions Integration

Your `.github/workflows/deploy.yml` works perfectly:

```yaml
- name: Deploy
  run: |
    cd /opt/tipjar
    docker-compose pull
    docker-compose up -d
```

Traefik automatically picks up the new container and routes traffic! ✨

---

## 📈 Examples

### Example 1: Multiple Domains

```yaml
labels:
  - "traefik.http.routers.tipjar.rule=Host(`tipjar.mucks.me`) || Host(`tip.mucks.me`)"
```

### Example 2: Path-Based Routing

```yaml
labels:
  - "traefik.http.routers.api.rule=Host(`tipjar.mucks.me`) && PathPrefix(`/api`)"
```

### Example 3: Add Basic Auth

```yaml
labels:
  - "traefik.http.routers.admin.middlewares=admin-auth"
  - "traefik.http.middlewares.admin-auth.basicauth.users=admin:$$apr1$$..."
```

### Example 4: Rate Limiting

```yaml
labels:
  - "traefik.http.routers.tipjar.middlewares=rate-limit"
  - "traefik.http.middlewares.rate-limit.ratelimit.average=100"
  - "traefik.http.middlewares.rate-limit.ratelimit.burst=50"
```

---

## 🚀 Complete Example Setup

### 1. Copy Files to Server

```bash
# On your local machine
cd /Users/mucks/Projects/rust-smart-contracts/tipjar

# Copy Traefik setup
scp -r traefik user@your-server.com:/opt/

# Copy Tipjar docker-compose.yml
scp docker-compose.yml user@your-server.com:/opt/tipjar/
```

### 2. Set Up on Server

```bash
# SSH to server
ssh user@your-server.com

# Set up Traefik
cd /opt/traefik
cp env.example .env
nano .env  # Configure

mkdir -p letsencrypt logs
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json

docker network create web
docker-compose up -d

# Set up Tipjar
cd /opt/tipjar
cat > .env << EOF
NEXT_PUBLIC_SOLANA_NETWORK=https://api.devnet.solana.com
TIPJAR_DOMAIN=tipjar.mucks.me
EOF

docker-compose up -d
```

### 3. Done!

Visit:
- https://tipjar.mucks.me (Tipjar)
- https://traefik.mucks.me (Dashboard)

---

## 💡 Benefits of This Setup

✅ **One Traefik for Everything** - Manage all services from one place
✅ **Easy to Add Services** - Just add docker-compose.yml with labels
✅ **Automatic SSL** - Let's Encrypt for all domains
✅ **Git-Friendly** - All configuration in YAML files
✅ **Centralized Monitoring** - One dashboard for all services
✅ **Resource Efficient** - One reverse proxy for everything
✅ **Simple Updates** - Update services independently

---

## 📚 File Templates

### Template: traefik/docker-compose.yml

Located in `/Users/mucks/Projects/rust-smart-contracts/tipjar/traefik/docker-compose.yml`

Copy this to `/opt/traefik/` on your server.

### Template: docker-compose.yml (Tipjar)

Located in `/Users/mucks/Projects/rust-smart-contracts/tipjar/docker-compose.yml`

Copy this to `/opt/tipjar/` on your server.

### Template: New Service

```yaml
version: '3.8'

services:
  your-service:
    image: your-image:latest
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.yourservice.rule=Host(`your.domain.com`)"
      - "traefik.http.routers.yourservice.entrypoints=websecure"
      - "traefik.http.routers.yourservice.tls.certresolver=letsencrypt"
      - "traefik.http.services.yourservice.loadbalancer.server.port=PORT"

networks:
  web:
    external: true
```

---

## 🎉 Summary

**Two files, unlimited services:**

1. **`/opt/traefik/docker-compose.yml`** - Central Traefik (set up once)
2. **`/opt/tipjar/docker-compose.yml`** - Tipjar (or any service)

**Add new services anytime** by creating a new docker-compose.yml with Traefik labels!

---

**Questions? Check `TRAEFIK_QUICKSTART.md` or `TRAEFIK_VS_NPM.md`!**

