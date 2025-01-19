#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
VPN_DIR="/usr/local/vpn"
CERT_DIR="$VPN_DIR/cert"
CONFIG_DIR="$VPN_DIR/config"
DOMAIN_CONF="$CONFIG_DIR/domain.conf"
XRAY_CONFIG_DIR="$CONFIG_DIR/xray"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Function to validate subdomain format
validate_subdomain() {
    local subdomain="$1"
    if [[ ! "$subdomain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*\.[a-zA-Z0-9][a-zA-Z0-9-]*\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Function to update all configuration files with new domain
update_domain_configs() {
    local domain="$1"

    # Update domain.conf
    echo "$domain" >"$DOMAIN_CONF"
    chmod 600 "$DOMAIN_CONF"

    # Update Xray configurations
    if [ -d "$XRAY_CONFIG_DIR" ]; then
        for config in "$XRAY_CONFIG_DIR"/*.json; do
            if [ -f "$config" ]; then
                sed -i "s/\"host\": \".*\"/\"host\": \"$domain\"/" "$config"
                sed -i "s/\"serverName\": \".*\"/\"serverName\": \"$domain\"/" "$config"
                chmod 600 "$config"
            fi
        done
    fi

    # Update Nginx configuration
    local nginx_conf="/etc/nginx/conf.d/xray.conf"
    if [ -f "$nginx_conf" ]; then
        sed -i "s/server_name .*;/server_name $domain;/" "$nginx_conf"
    fi

    # Update Stunnel configuration
    local stunnel_conf="$CONFIG_DIR/stunnel5/stunnel5.conf"
    if [ -f "$stunnel_conf" ]; then
        sed -i "s|^cert = .*|cert = /usr/local/vpn/cert/fullchain.pem|" "$stunnel_conf"
        sed -i "s|^key = .*|key = /usr/local/vpn/cert/privkey.pem|" "$stunnel_conf"
        chmod 600 "$stunnel_conf"
    fi
}

# Function to install certbot if not present
install_certbot() {
    if ! command -v certbot &>/dev/null; then
        apt-get update
        apt-get install -y certbot
    fi
}

# Function to request SSL certificate
setup_ssl_certificate() {
    local subdomain="$1"

    # Install certbot if needed
    install_certbot

    # Validate subdomain
    if ! validate_subdomain "$subdomain"; then
        echo -e "${RED}Invalid subdomain format: $subdomain${NC}"
        exit 1
    fi

    # Update configurations
    update_domain_configs "$subdomain"

    # Stop services
    systemctl stop nginx xray stunnel5

    # Request certificate
    certbot certonly --standalone \
        -d "$subdomain" \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email \
        --preferred-challenges http

    if [ $? -eq 0 ]; then
        # Create cert directory with proper permissions
        mkdir -p "$CERT_DIR"
        chmod 700 "$CERT_DIR"

        # Copy and secure certificates
        cp /etc/letsencrypt/live/"$subdomain"/fullchain.pem "$CERT_DIR/"
        cp /etc/letsencrypt/live/"$subdomain"/privkey.pem "$CERT_DIR/"
        chmod 400 "$CERT_DIR"/*.pem

        # Setup auto-renewal
        cat >/etc/systemd/system/certbot-renewal-hooks.service <<EOF
[Unit]
Description=Certbot renewal hooks
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/systemctl stop nginx
ExecStartPost=/bin/systemctl start nginx
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable certbot-renewal-hooks.service

        # Create renewal hooks
        mkdir -p /etc/letsencrypt/renewal-hooks/{pre,post}

        echo '#!/bin/bash' >/etc/letsencrypt/renewal-hooks/pre/stop-services.sh
        echo 'systemctl stop nginx xray stunnel5' >>/etc/letsencrypt/renewal-hooks/pre/stop-services.sh

        echo '#!/bin/bash' >/etc/letsencrypt/renewal-hooks/post/start-services.sh
        echo 'cp /etc/letsencrypt/live/'"$subdomain"'/*.pem /usr/local/vpn/cert/' >>/etc/letsencrypt/renewal-hooks/post/start-services.sh
        echo 'chmod 400 /usr/local/vpn/cert/*.pem' >>/etc/letsencrypt/renewal-hooks/post/start-services.sh
        echo 'systemctl start nginx xray stunnel5' >>/etc/letsencrypt/renewal-hooks/post/start-services.sh

        chmod +x /etc/letsencrypt/renewal-hooks/{pre,post}/*.sh

        # Start services
        systemctl start nginx xray stunnel5

        clear
        exit 0
    else
        systemctl start nginx xray stunnel5
        echo -e "${RED}Failed to obtain SSL certificate${NC}"
        exit 1
    fi
}

# Check if domain provided as argument
if [ -z "$1" ]; then
    echo -e "${RED}Please provide subdomain as argument${NC}"
    echo -e "Usage: $0 subdomain.domain.tld"
    exit 1
fi

# Run the SSL setup with provided domain
setup_ssl_certificate "$1"
