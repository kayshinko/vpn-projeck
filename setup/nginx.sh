#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Install Nginx
install_nginx() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║             Nginx Installation                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

    # Update package lists
    echo -e "${YELLOW}Updating package lists...${NC}"
    apt-get update -y

    # Install required dependencies
    echo -e "${YELLOW}Installing required dependencies...${NC}"
    apt-get install -y \
        curl \
        gnupg \
        ca-certificates \
        lsb-release

    # Add Nginx official repository
    echo -e "${YELLOW}Adding Nginx official repository...${NC}"
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

    # Setup repository
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list

    # Update package lists again
    apt-get update -y

    # Install Nginx
    echo -e "${YELLOW}Installing Nginx...${NC}"
    apt-get install -y nginx

    # Create VPN configuration directory
    mkdir -p /root/vpn/config/nginx/conf.d

    # Copy VPN-specific Nginx configuration
    cp /root/vpn/config/nginx/conf.d/xray.conf /etc/nginx/conf.d/xray.conf

    # Configure Nginx
    configure_nginx
}

# Configure Nginx security and performance
configure_nginx() {
    echo -e "${YELLOW}Configuring Nginx security and performance...${NC}"

    # Backup original configuration
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

    # Update Nginx main configuration
    cat >/etc/nginx/nginx.conf <<EOL
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    multi_accept on;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Limits
    limit_req_log_level warn;
    limit_req_zone \$binary_remote_addr zone=login:10m rate=10r/m;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;

    # Include VPN configurations
    include /etc/nginx/conf.d/*.conf;
}
EOL

    # Enable and restart Nginx
    systemctl enable nginx
    systemctl restart nginx
}

# Verify Nginx installation
verify_installation() {
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}Nginx installed and running successfully!${NC}"
        nginx -v
    else
        echo -e "${RED}Failed to start Nginx service${NC}"
        exit 1
    fi
}

# Main installation process
main() {
    install_nginx
    verify_installation
}

# Run main function
main
