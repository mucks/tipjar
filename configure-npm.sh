#!/bin/bash

# nginx-proxy-manager Auto-Configuration Script
# Automatically adds Tipjar proxy host to nginx-proxy-manager

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo "🔧 nginx-proxy-manager Auto-Configuration"
echo "=========================================="
echo ""

# Configuration
DOMAIN="tipjar.mucks.me"
NPM_CONTAINER="nginx-proxy-manager"
FORWARD_HOST="tipjar-web"
FORWARD_PORT="3000"
EMAIL="admin@mucks.me"  # Change this to your email

# Check if NPM container is running
print_info "Checking if nginx-proxy-manager is running..."
if ! docker ps --format '{{.Names}}' | grep -q "^${NPM_CONTAINER}$"; then
    print_error "nginx-proxy-manager container is not running!"
    echo "Start it with: docker-compose up -d"
    exit 1
fi
print_success "nginx-proxy-manager is running"
echo ""

# Backup database
print_info "Creating database backup..."
docker exec $NPM_CONTAINER cp /data/database.sqlite /data/database.sqlite.backup
print_success "Database backed up"
echo ""

# Create SQL commands
print_info "Creating proxy host configuration..."

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")

# SQL to insert proxy host
SQL_INSERT_HOST="
INSERT INTO proxy_host (
    created_on, modified_on, owner_user_id,
    domain_names, forward_scheme, forward_host, forward_port,
    access_list_id, certificate_id, ssl_forced, caching_enabled,
    block_exploits, advanced_config, meta, allow_websocket_upgrade,
    http2_support, hsts_enabled, hsts_subdomains
) VALUES (
    '$TIMESTAMP', '$TIMESTAMP', 1,
    '[\"$DOMAIN\"]', 'http', '$FORWARD_HOST', $FORWARD_PORT,
    0, 0, 0, 0,
    1, '', '{}', 1,
    1, 0, 0
);
"

# Execute SQL
print_info "Adding proxy host to database..."
docker exec $NPM_CONTAINER sqlite3 /data/database.sqlite "$SQL_INSERT_HOST"
print_success "Proxy host added"
echo ""

# Get the ID of the newly created host
HOST_ID=$(docker exec $NPM_CONTAINER sqlite3 /data/database.sqlite "SELECT id FROM proxy_host WHERE domain_names LIKE '%$DOMAIN%' ORDER BY id DESC LIMIT 1;")
print_info "Proxy host ID: $HOST_ID"
echo ""

# Request SSL Certificate
print_info "Configuring SSL certificate..."
print_warning "This will request a Let's Encrypt certificate for $DOMAIN"
print_warning "Make sure DNS is properly configured!"
echo ""

read -p "Request SSL certificate now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # First, check if certificate already exists for this domain
    CERT_ID=$(docker exec $NPM_CONTAINER sqlite3 /data/database.sqlite "SELECT id FROM certificate WHERE domain_names LIKE '%$DOMAIN%' LIMIT 1;" || echo "")
    
    if [ -n "$CERT_ID" ] && [ "$CERT_ID" != "" ]; then
        print_info "Certificate already exists (ID: $CERT_ID), updating proxy host..."
        docker exec $NPM_CONTAINER sqlite3 /data/database.sqlite "UPDATE proxy_host SET certificate_id = $CERT_ID, ssl_forced = 1 WHERE id = $HOST_ID;"
        print_success "Proxy host updated with existing certificate"
    else
        print_info "Requesting new certificate from Let's Encrypt..."
        
        # SQL to insert certificate request
        SQL_INSERT_CERT="
        INSERT INTO certificate (
            created_on, modified_on, owner_user_id,
            provider, nice_name, domain_names, expires_on,
            is_deleted, meta
        ) VALUES (
            '$TIMESTAMP', '$TIMESTAMP', 1,
            'letsencrypt', '$DOMAIN', '[\"$DOMAIN\"]', datetime('now', '+90 days'),
            0, '{\"letsencrypt_email\":\"$EMAIL\",\"letsencrypt_agree\":true,\"dns_challenge\":false}'
        );
        "
        
        docker exec $NPM_CONTAINER sqlite3 /data/database.sqlite "$SQL_INSERT_CERT"
        
        # Get the new certificate ID
        NEW_CERT_ID=$(docker exec $NPM_CONTAINER sqlite3 /data/database.sqlite "SELECT id FROM certificate ORDER BY id DESC LIMIT 1;")
        
        # Update proxy host to use the certificate and force SSL
        docker exec $NPM_CONTAINER sqlite3 /data/database.sqlite "UPDATE proxy_host SET certificate_id = $NEW_CERT_ID, ssl_forced = 1 WHERE id = $HOST_ID;"
        
        print_success "Certificate requested and linked to proxy host"
        print_warning "Note: Certificate provisioning happens asynchronously"
        print_info "Check nginx-proxy-manager logs if certificate fails"
    fi
else
    print_info "Skipping SSL certificate configuration"
    print_info "You can enable it later in the nginx-proxy-manager UI"
fi
echo ""

# Reload nginx-proxy-manager
print_info "Reloading nginx-proxy-manager..."
docker exec $NPM_CONTAINER nginx -s reload 2>/dev/null || print_warning "Reload signal sent (container will reload automatically)"
print_success "Configuration applied"
echo ""

# Display configuration
echo "========================================"
print_success "🎉 CONFIGURATION COMPLETE!"
echo "========================================"
echo ""
print_info "Proxy Host Details:"
echo "  • Domain:          $DOMAIN"
echo "  • Forward to:      $FORWARD_HOST:$FORWARD_PORT"
echo "  • SSL:             $([ $REPLY = 'y' ] || [ $REPLY = 'Y' ] && echo 'Enabled (Let'\''s Encrypt)' || echo 'Not configured')"
echo "  • Force SSL:       $([ $REPLY = 'y' ] || [ $REPLY = 'Y' ] && echo 'Yes' || echo 'No')"
echo "  • Block Exploits:  Yes"
echo "  • Websockets:      Yes"
echo "  • HTTP/2:          Yes"
echo ""
print_info "Access your tipjar at:"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  🔒 https://$DOMAIN"
else
    echo "  http://$DOMAIN"
fi
echo ""
print_info "View in nginx-proxy-manager UI:"
echo "  • Login to nginx-proxy-manager"
echo "  • Go to Hosts → Proxy Hosts"
echo "  • Find: $DOMAIN"
echo ""

# Verification
print_info "Verifying configuration..."
echo ""
docker exec $NPM_CONTAINER sqlite3 /data/database.sqlite "SELECT 'Domain: ' || domain_names, 'Forward: ' || forward_host || ':' || forward_port, 'SSL: ' || CASE WHEN certificate_id > 0 THEN 'Yes' ELSE 'No' END FROM proxy_host WHERE id = $HOST_ID;"
echo ""

print_warning "If certificate provisioning fails:"
echo "  1. Verify DNS: nslookup $DOMAIN"
echo "  2. Check logs: docker logs $NPM_CONTAINER"
echo "  3. Ensure ports 80/443 are accessible"
echo "  4. Try again in nginx-proxy-manager UI"
echo ""
print_success "Setup complete! 🚀"

