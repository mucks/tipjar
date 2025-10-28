# Central Traefik Configuration

This is your **central Traefik reverse proxy** configuration.

## 🎯 Purpose

One Traefik instance to handle **all your services**:
- Tipjar
- Future projects
- Any Docker service

## 🚀 Quick Setup

```bash
# On your server
mkdir -p /opt/traefik
cd /opt/traefik

# Copy files from this directory
# - docker-compose.yml
# - env.example

# Configure
cp env.example .env
nano .env  # Update with your settings

# Prepare
mkdir -p letsencrypt logs
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json
docker network create web

# Start
docker-compose up -d
```

## 📋 What It Does

- **Reverse Proxy**: Routes traffic to your services
- **Automatic HTTPS**: Let's Encrypt SSL certificates
- **Auto-Renewal**: Handles certificate renewal
- **Dashboard**: Web UI at https://traefik.mucks.me
- **Service Discovery**: Automatically finds Docker containers

## 🔧 Configuration

Edit `.env` file:

```bash
ACME_EMAIL=admin@mucks.me        # Your email for Let's Encrypt
TRAEFIK_DOMAIN=traefik.mucks.me  # Dashboard domain
TRAEFIK_BASIC_AUTH=admin:...     # Dashboard login (htpasswd format)
LOG_LEVEL=INFO                   # Logging level
```

## 📂 Directory Structure

```
/opt/traefik/
├── docker-compose.yml   # Traefik configuration
├── .env                 # Your settings
├── letsencrypt/
│   └── acme.json       # SSL certificates (auto-managed)
└── logs/
    ├── access.log      # HTTP access logs
    └── traefik.log     # Traefik logs
```

## 🌐 DNS Requirements

Point your domains to your server:

```
traefik.mucks.me  → your-server-ip
```

(Other services need their own DNS too)

## 🔐 Security

### Generate Dashboard Password

```bash
docker run --rm httpd:alpine htpasswd -nb admin yourpassword
```

Copy the output to `.env` file (escape $ as $$)

### Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## 📊 Accessing Dashboard

**URL**: https://traefik.mucks.me

**Login**: 
- Username: `admin`
- Password: (what you set in .env)

**Features**:
- View all services
- See routing rules
- Monitor SSL certificates
- View request metrics

## 🔄 Management

```bash
# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Stop
docker-compose down

# Update
docker-compose pull
docker-compose up -d

# View access logs
tail -f logs/access.log
```

## 🎯 Adding Services

Services automatically connect if they:

1. Are on the `web` network
2. Have Traefik labels
3. Have `traefik.enable=true`

Example service configuration:

```yaml
networks:
  - web
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`myapp.mucks.me`)"
  - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
  - "traefik.http.services.myapp.loadbalancer.server.port=8080"
```

## 🐛 Troubleshooting

### Check if Traefik is running

```bash
docker ps | grep traefik
```

### Check logs for errors

```bash
docker-compose logs | grep -i error
```

### View network

```bash
docker network inspect web
```

### Test SSL

```bash
curl -I https://traefik.mucks.me
```

## 📚 Full Documentation

See `../TRAEFIK_SETUP.md` for complete guide.

---

**Set it up once, use it forever!** 🚀

