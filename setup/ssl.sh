#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
VPN_DIR="/root/vpn"
CERT_DIR="$VPN_DIR/cert"
CONFIG_DIR="$VPN_DIR/config"

# Cloudflare API Configuration File
CLOUDFLARE_CONFIG="$CONFIG_DIR/cloudflare.conf"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Function to validate domain
validate_domain() {
    local domain="$1"
    # Basic domain validation regex
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Function to install Certbot
install_certbot() {
    echo -e "${YELLOW}Installing Certbot...${NC}"
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
}

# Function to request SSL certificate
request_ssl_certificate() {
    # Clear screen
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           SSL Certificate Installation               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"

    # Domain input with validation
    while true; do
        read -p "Enter your domain (e.g., vpn.example.com): " domain

        # Validate domain
        if validate_domain "$domain"; then
            # Confirm domain
            read -p "Confirm domain $domain? [Y/n]: " confirm
            confirm=${confirm:-Y}

            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                break
            fi
        else
            echo -e "${RED}Invalid domain format. Please use a valid domain name.${NC}"
        fi
    done

    # Additional domain configuration
    read -p "Add www subdomain? [Y/n]: " add_www
    add_www=${add_www:-Y}

    # Prepare domain arguments
    if [[ "$add_www" =~ ^[Yy]$ ]]; then
        domain_args="-d $domain -d www.$domain"
    else
        domain_args="-d $domain"
    fi

    # Request certificate
    echo -e "${YELLOW}Requesting SSL Certificate for $domain...${NC}"

    # Install Certbot if not already installed
    install_certbot

    # Request certificate with Nginx validation
    certbot certonly --nginx $domain_args \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email

    # Check certificate generation
    if [ $? -eq 0 ]; then
        # Copy certificates to VPN directory
        mkdir -p "$CERT_DIR"
        cp /etc/letsencrypt/live/"$domain"/fullchain.pem "$CERT_DIR/"
        cp /etc/letsencrypt/live/"$domain"/privkey.pem "$CERT_DIR/"

        # Update domain configuration
        echo "$domain" >"$CONFIG_DIR/domain.conf"

        echo -e "${GREEN}SSL Certificate installed successfully!${NC}"
        echo -e "Domain: ${YELLOW}$domain${NC}"
        echo -e "Certificate Location: ${YELLOW}$CERT_DIR${NC}"

        # Update Nginx configuration
        update_nginx_config "$domain"

        return 0
    else
        echo -e "${RED}Failed to generate SSL Certificate${NC}"
        return 1
    fi
}

# Function to update Nginx configuration
update_nginx_config() {
    local domain="$1"
    local nginx_config="/etc/nginx/conf.d/xray.conf"

    # Check if Nginx configuration exists
    if [ ! -f "$nginx_config" ]; then
        echo -e "${YELLOW}Nginx configuration not found. Skipping update.${NC}"
        return
    fi

    # Update server_name in Nginx config
    sed -i "s/server_name .*;/server_name $domain www.$domain;/" "$nginx_config"

    # Restart Nginx to apply changes
    systemctl restart nginx

    echo -e "${GREEN}Nginx configuration updated for $domain${NC}"
}

# Main SSL management function
ssl_management() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         SSL and Domain Management                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

    echo -e "SSL Management Options:"
    echo -e " [1] Install SSL Certificate"
    echo -e " [2] Renew Existing Certificate"
    echo -e " [3] Back to Main Menu"

    read -p "Select an option [1-3]: " ssl_option

    case $ssl_option in
    1)
        request_ssl_certificate
        ;;
    2)
        # Renew certificates
        certbot renew --force-renewal
        ;;
    3)
        return 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
    esac

    read -n 1 -s -r -p "Press any key to continue..."
}

# Run the SSL management
ssl_management
