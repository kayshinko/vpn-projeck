#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Stunnel5 version
STUNNEL_VERSION="5.71"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Function to generate self-signed certificate
generate_certificate() {
    local cert_path="/root/vpn/config/stunnel5/stunnel5.pem"

    # Create directory if not exists
    mkdir -p "$(dirname "$cert_path")"

    # Generate self-signed certificate
    openssl req -new -x509 -days 365 -nodes \
        -out "$cert_path" \
        -keyout "$cert_path" \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=VPN Management/CN=vpn.example.com"

    # Set proper permissions
    chmod 600 "$cert_path"
}

# Install Stunnel5
install_stunnel5() {
    # Update package lists
    apt-get update

    # Install dependencies
    apt-get install -y \
        build-essential \
        libssl-dev \
        wget \
        tar \
        gzip

    # Download Stunnel5
    cd /tmp
    wget https://www.stunnel.org/downloads/stunnel-${STUNNEL_VERSION}.tar.gz
    tar -xzvf stunnel-${STUNNEL_VERSION}.tar.gz
    cd stunnel-${STUNNEL_VERSION}

    # Configure and compile
    ./configure
    make
    make install

    # Create symbolic link
    ln -sf /usr/local/bin/stunnel /usr/bin/stunnel

    # Create systemd service file
    cat >/etc/systemd/system/stunnel5.service <<EOL
[Unit]
Description=Stunnel5 SSL Tunnel
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/stunnel /root/vpn/config/stunnel5/stunnel5.conf
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemd
    systemctl daemon-reload
    systemctl enable stunnel5
    systemctl start stunnel5
}

# Main installation function
main() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║             Stunnel5 Installation                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

    # Generate certificate
    echo -e "${YELLOW}Generating self-signed SSL certificate...${NC}"
    generate_certificate

    # Install Stunnel5
    echo -e "${YELLOW}Installing Stunnel5...${NC}"
    install_stunnel5

    # Verify installation
    if systemctl is-active --quiet stunnel5; then
        echo -e "${GREEN}Stunnel5 installed and running successfully!${NC}"
    else
        echo -e "${RED}Failed to start Stunnel5 service${NC}"
        exit 1
    fi
}

# Run main function
main
