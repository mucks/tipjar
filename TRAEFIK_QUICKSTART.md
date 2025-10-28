# 🚀 Traefik Quick Start

Get Tipjar running with Traefik in 3 minutes!

---

## ⚡ Super Quick Setup

```bash
# 1. Run setup script
./setup-traefik.sh

# 2. Done! 🎉
```

Visit:
- **https://tipjar.mucks.me** - Your tipjar
- **https://traefik.mucks.me** - Traefik dashboard

---

## 📋 What You Need

### Before Running Setup

1. **DNS configured:**
   ```
   tipjar.mucks.me  → your-server-ip
   traefik.mucks.me → your-server-ip
   ```

2. **Ports open:**
   - 80 (HTTP)
   - 443 (HTTPS)

That's it!

---

## 🎯 The Setup Script Does Everything

```bash
./setup-traefik.sh
```

**It will:**
1. ✅ Create `/opt/tipjar` directory
2. ✅ Create Docker network
3. ✅ Generate docker-compose.yml
4. ✅ Ask for GitHub username
5. ✅ Set admin password
6. ✅ Configure Let's Encrypt
7. ✅ Start Traefik + Tipjar
8. ✅ Request SSL certificates automatically

**Time: 2-3 minutes**

---

## 🔍 What You Get

### Automatic HTTPS for Both Domains

**tipjar.mucks.me:**
- Your Tipjar application
- Automatic SSL from Let's Encrypt
- HTTP → HTTPS redirect

**traefik.mucks.me:**
- Traefik dashboard
- See all your services
- Monitor traffic
- View SSL certificates
- Basic auth protected

---

## 🛠️ Common Commands

```bash
# View logs
docker-compose logs -f

# View only Traefik logs
docker-compose logs -f traefik

# View only Tipjar logs
docker-compose logs -f tipjar

# Restart services
docker-compose restart

# Stop everything
docker-compose down

# Update Tipjar
docker-compose pull tipjar
docker-compose up -d

# Check status
docker-compose ps
```

---

## 🔧 Adding More Services

Want to add another service? Just add it to `docker-compose.yml`:

```yaml
services:
  # ... existing services ...
  
  my-new-app:
    image: my-app:latest
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.mucks.me`)"
      - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"
```

```bash
docker-compose up -d
```

**Done!** SSL and everything works automatically! ✨

---

## 📊 Configuration Files

After setup, you'll have:

```
/opt/tipjar/
├── docker-compose.yml    # Service configuration
├── .env                  # Environment variables
└── letsencrypt/
    └── acme.json        # SSL certificates (auto-managed)
```

---

## 🔐 Traefik Dashboard Access

**URL:** https://traefik.mucks.me

**Login:**
- Username: `admin`
- Password: (the one you set during setup)

**Features:**
- View all services
- Monitor requests
- Check SSL certificate status
- See real-time metrics

---

## 🎯 GitHub Actions Integration

Your `.github/workflows/deploy.yml` works perfectly with Traefik!

When you push to GitHub:
1. GitHub Actions builds Docker image
2. Pushes to registry
3. SSHs to server
4. Runs `docker-compose pull && docker-compose up -d`
5. **Traefik automatically routes traffic** ✨
6. **SSL works immediately**

No manual configuration needed!

---

## 🐛 Troubleshooting

### SSL Certificate Not Working

**Check DNS:**
```bash
nslookup tipjar.mucks.me
# Should show your server IP
```

**Check Traefik logs:**
```bash
docker-compose logs traefik | grep -i "error\|certificate"
```

**Common issues:**
- DNS not propagated (wait 5-10 minutes)
- Port 80 blocked (Let's Encrypt needs it)
- Domain already has rate limit (wait 1 hour)

### Can't Access Dashboard

**Check Traefik is running:**
```bash
docker ps | grep traefik
```

**Test login:**
```bash
curl -u admin:yourpassword https://traefik.mucks.me
```

**Reset password:**
```bash
# Generate new password hash
docker run --rm httpd:alpine htpasswd -nb admin newpassword

# Update .env file with new hash
nano .env
# Update TRAEFIK_AUTH line

# Restart
docker-compose restart traefik
```

### Service Not Accessible

**Check labels:**
```bash
docker inspect tipjar-web | grep -A 20 Labels
```

**Check network:**
```bash
docker network inspect web
# Should show both traefik and tipjar-web
```

**Restart everything:**
```bash
docker-compose down
docker-compose up -d
```

---

## 📈 Monitoring

### View Real-Time Requests

**Dashboard:** https://traefik.mucks.me → HTTP

### View Logs

```bash
# All logs
docker-compose logs -f

# Filter for errors
docker-compose logs -f | grep -i error

# Filter for a specific service
docker-compose logs -f tipjar
```

### Check Certificate Expiry

**Dashboard:** https://traefik.mucks.me → HTTP Routers → Click your service

Or via command:
```bash
echo | openssl s_client -servername tipjar.mucks.me -connect tipjar.mucks.me:443 2>/dev/null | openssl x509 -noout -dates
```

---

## 🔄 Updating

### Update Traefik

```bash
cd /opt/tipjar
docker-compose pull traefik
docker-compose up -d traefik
```

### Update Tipjar

```bash
cd /opt/tipjar
docker-compose pull tipjar
docker-compose up -d tipjar
```

### Update Both

```bash
cd /opt/tipjar
docker-compose pull
docker-compose up -d
```

---

## 🎓 Understanding the Configuration

### Key Parts of docker-compose.yml

```yaml
# Traefik listens on ports
ports:
  - "80:80"
  - "443:443"

# Traefik watches Docker
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro

# Services are configured with labels
labels:
  - "traefik.enable=true"                              # Enable routing
  - "traefik.http.routers.X.rule=Host(`domain`)"      # Domain routing
  - "traefik.http.routers.X.tls.certresolver=le"      # Use Let's Encrypt
  - "traefik.http.services.X.loadbalancer.port=3000"  # Backend port
```

---

## 💡 Pro Tips

### 1. **Multiple Domains for One Service**

```yaml
- "traefik.http.routers.tipjar.rule=Host(`tipjar.mucks.me`) || Host(`tip.mucks.me`)"
```

### 2. **Add Path-Based Routing**

```yaml
- "traefik.http.routers.api.rule=Host(`tipjar.mucks.me`) && PathPrefix(`/api`)"
```

### 3. **Add Security Headers**

```yaml
- "traefik.http.routers.tipjar.middlewares=secure-headers"
- "traefik.http.middlewares.secure-headers.headers.sslredirect=true"
- "traefik.http.middlewares.secure-headers.headers.stsSeconds=31536000"
```

### 4. **Add Rate Limiting**

```yaml
- "traefik.http.middlewares.ratelimit.ratelimit.average=100"
- "traefik.http.middlewares.ratelimit.ratelimit.burst=50"
- "traefik.http.routers.tipjar.middlewares=ratelimit"
```

---

## 🌟 Why This Setup Rocks

✅ **Zero manual configuration** - Everything in docker-compose.yml
✅ **Automatic SSL** - Let's Encrypt handles it
✅ **Git-friendly** - Commit your configuration
✅ **CI/CD ready** - GitHub Actions just works
✅ **Fast** - 30 seconds from push to live
✅ **Scalable** - Add services in seconds

---

## 📚 More Resources

- **Full Comparison:** `TRAEFIK_VS_NPM.md`
- **Docker Deployment:** `DOCKER_DEPLOYMENT.md`
- **GitHub Actions:** `.github/workflows/deploy.yml`

---

## 🎉 Summary

```bash
# Setup
./setup-traefik.sh

# Deploy new versions
git push origin main
# GitHub Actions deploys automatically

# Add new services
# Just edit docker-compose.yml
docker-compose up -d
```

**That's it! Simple, automated, perfect!** 🚀

---

**Questions? Check `TRAEFIK_VS_NPM.md` for detailed comparison!**

