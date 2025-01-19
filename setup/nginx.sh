#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
VPN_DIR="/usr/local/vpn"
NGINX_DIR="$VPN_DIR/config/nginx"
NGINX_CONF="$NGINX_DIR/conf.d"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Function to install Nginx
install_nginx() {
    # Update package lists
    apt-get update -y

    # Install required dependencies
    apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring

    # Add Nginx official repository
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor >/usr/share/keyrings/nginx-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" >/etc/apt/sources.list.d/nginx.list

    # Update and install Nginx
    apt-get update -y
    apt-get install -y nginx

    # Create VPN configuration directories
    mkdir -p "$NGINX_CONF"
    chmod 700 "$NGINX_DIR" "$NGINX_CONF"
}

# Function to configure Nginx
configure_nginx() {
    # Backup original configuration
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

    # Create optimized Nginx configuration
    cat >/etc/nginx/nginx.conf <<EOL
user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
pid /var/run/nginx.pid;

events {
    worker_connections 65535;
    multi_accept on;
    use epoll;
}

http {
    charset utf-8;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    server_tokens off;
    log_not_found off;
    types_hash_max_size 2048;
    client_max_body_size 16M;

    # MIME
    include mime.types;
    default_type application/octet-stream;

    # Logging
    access_log /var/log/nginx/access.log combined buffer=512k flush=1m;
    error_log /var/log/nginx/error.log warn;

    # Connection header for WebSocket reverse proxy
    map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ""      close;
    }

    # Limits & Timeouts
    limit_req_log_level warn;
    limit_req_zone \$binary_remote_addr zone=login:10m rate=10r/s;
    
    client_body_timeout 15s;
    client_header_timeout 15s;
    keepalive_timeout 65s;
    send_timeout 15s;

    # Buffer Sizes
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    client_max_body_size 16m;
    large_client_header_buffers 4 8k;

    # SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_buffer_size 4k;

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 1.0.0.1 valid=60s;
    resolver_timeout 2s;

    # Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;

    # Max Body Size for Upload
    client_max_body_size 16m;

    # File Descriptor Cache
    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    # Include VPN configurations
    include /etc/nginx/conf.d/*.conf;
}
EOL

    # Create default Xray configuration
    cat >/etc/nginx/conf.d/xray.conf <<EOL
server {
    listen 80;
    listen [::]:80;
    server_name _;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name _;
    
    ssl_certificate $VPN_DIR/cert/fullchain.pem;
    ssl_certificate_key $VPN_DIR/cert/privkey.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location / {
        return 404;
    }

    location /xray {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

    # Set proper permissions
    chown -R nginx:nginx /etc/nginx
    chmod 644 /etc/nginx/nginx.conf
    chmod 644 /etc/nginx/conf.d/xray.conf

    # Create nginx cache directory with proper permissions
    mkdir -p /var/cache/nginx
    chmod 700 /var/cache/nginx
    chown nginx:nginx /var/cache/nginx
}

# Function to verify installation
verify_nginx() {
    nginx -t
    if [ $? -eq 0 ]; then
        systemctl enable nginx
        systemctl restart nginx
        if systemctl is-active --quiet nginx; then
            return 0
        fi
    fi
    return 1
}

# Main function
main() {
    install_nginx
    configure_nginx
    if verify_nginx; then
        clear
    else
        echo -e "${RED}Nginx installation or configuration failed${NC}"
        exit 1
    fi
}

# Run main installation
main
