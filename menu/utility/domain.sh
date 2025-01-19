#!/bin/bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Path
SCRIPT_DIR="/usr/local/vpn"
DOMAIN_CONFIG="$SCRIPT_DIR/config/domain.conf"
XRAY_DIR="$SCRIPT_DIR/config/xray"
NGINX_CONFIG="/etc/nginx/sites-available/default"

# Function untuk validasi domain
validate_domain() {
    local domain="$1"
    # Basic domain validation regex
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Function untuk mengatur domain
manage_domain() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Domain Management"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Current domain
    current_domain=$(cat "$DOMAIN_CONFIG" 2>/dev/null || echo "Not Set")
    echo -e "Current Domain: ${YELLOW}$current_domain${NC}"

    echo -e "\nOptions:"
    echo -e " [1] Change Domain"
    echo -e " [2] Verify Domain Configuration"
    echo -e " [3] Install SSL Certificate"
    echo -e " [4] Back to Menu"

    read -p "Select an option [1-4]: " domain_option

    case $domain_option in
    1)
        # Change Domain
        while true; do
            read -p "Enter new domain: " new_domain

            # Validate domain
            if validate_domain "$new_domain"; then
                # Confirm
                read -p "Confirm domain $new_domain? [Y/n]: " confirm
                confirm=${confirm:-Y}

                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    # Save domain
                    echo "$new_domain" >"$DOMAIN_CONFIG"

                    # Update Xray configurations
                    for config in "$XRAY_DIR"/*.json; do
                        if [ -f "$config" ]; then
                            # Update domain in Xray configs
                            sed -i "s/\"host\": \".*\"/\"host\": \"$new_domain\"/" "$config"
                        fi
                    done

                    # Update Nginx configuration
                    sed -i "s/server_name .*;/server_name $new_domain;/" "$NGINX_CONFIG"

                    # Restart services
                    systemctl restart nginx
                    systemctl restart xray

                    echo -e "${GREEN}Domain updated successfully!${NC}"
                    break
                else
                    echo -e "${YELLOW}Domain change cancelled.${NC}"
                    break
                fi
            else
                echo -e "${RED}Invalid domain format. Please try again.${NC}"
            fi
        done
        ;;

    2)
        # Verify Domain Configuration
        echo -e "\n${YELLOW}Checking Domain Configuration:${NC}"

        # Check domain config
        if [ -f "$DOMAIN_CONFIG" ]; then
            echo -e "Domain Config: ${GREEN}Exists${NC}"
            echo -e "Domain: ${YELLOW}$(cat "$DOMAIN_CONFIG")${NC}"
        else
            echo -e "Domain Config: ${RED}Not Found${NC}"
        fi

        # Check DNS resolution
        if [ -n "$current_domain" ] && [ "$current_domain" != "Not Set" ]; then
            echo -e "\n${YELLOW}DNS Resolution Test:${NC}"
            dns_result=$(nslookup "$current_domain" 2>&1)
            if [[ "$dns_result" == *"NXDOMAIN"* ]]; then
                echo -e "${RED}Domain does not resolve${NC}"
            else
                echo -e "${GREEN}Domain resolves successfully${NC}"
            fi
        fi

        # Check SSL certificate
        echo -e "\n${YELLOW}SSL Certificate Check:${NC}"
        if [ -f "$SCRIPT_DIR/cert/fullchain.pem" ] && [ -f "$SCRIPT_DIR/cert/privkey.pem" ]; then
            cert_expiry=$(openssl x509 -in "$SCRIPT_DIR/cert/fullchain.pem" -noout -enddate | cut -d= -f2)
            echo -e "SSL Certificates: ${GREEN}Exist${NC}"
            echo -e "Expiration Date: ${YELLOW}$cert_expiry${NC}"
        else
            echo -e "SSL Certificates: ${RED}Not Found${NC}"
        fi

        read -n 1 -s -r -p "Press any key to continue"
        ;;

    3)
        # Install SSL Certificate
        echo -e "\n${YELLOW}SSL Certificate Installation${NC}"

        # Check domain is set
        if [ -z "$current_domain" ] || [ "$current_domain" == "Not Set" ]; then
            echo -e "${RED}Please set a domain first!${NC}"
            read -n 1 -s -r -p "Press any key to continue"
            break
        fi

        # Install Certbot if not exists
        if ! command -v certbot &>/dev/null; then
            echo -e "${YELLOW}Installing Certbot...${NC}"
            apt-get update
            apt-get install -y certbot python3-certbot-nginx
        fi

        # Request SSL certificate
        echo -e "${YELLOW}Requesting SSL Certificate for $current_domain...${NC}"
        certbot certonly --nginx -d "$current_domain" --non-interactive --agree-tos

        # Check certificate generation
        if [ $? -eq 0 ]; then
            # Copy certificates to VPN directory
            mkdir -p "$SCRIPT_DIR/cert"
            cp /etc/letsencrypt/live/"$current_domain"/fullchain.pem "$SCRIPT_DIR/cert/"
            cp /etc/letsencrypt/live/"$current_domain"/privkey.pem "$SCRIPT_DIR/cert/"

            echo -e "${GREEN}SSL Certificate installed successfully!${NC}"
            echo -e "Certificate Location: $SCRIPT_DIR/cert/"
        else
            echo -e "${RED}Failed to generate SSL Certificate${NC}"
        fi

        read -n 1 -s -r -p "Press any key to continue"
        ;;

    4)
        return 0
        ;;

    *)
        echo -e "${RED}Invalid option${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        ;;
    esac
}

# Run the function
manage_domain
