#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
VPN_DIR="/usr/local/vpn"
CONFIG_DIR="$VPN_DIR/config"
STUNNEL_DIR="$CONFIG_DIR/stunnel5"
CERT_DIR="$VPN_DIR/cert"

# Stunnel version and source
STUNNEL_VERSION="5.71"
STUNNEL_SOURCE="https://www.stunnel.org/downloads/stunnel-${STUNNEL_VERSION}.tar.gz"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Install dependencies
install_dependencies() {
    apt-get update
    apt-get install -y \
        build-essential \
        libssl-dev \
        openssl \
        wget \
        tar \
        gzip \
        net-tools \
        make
}

# Setup directories with proper permissions
setup_directories() {
    mkdir -p "$STUNNEL_DIR"
    chmod 700 "$STUNNEL_DIR"
    mkdir -p "$CERT_DIR"
    chmod 700 "$CERT_DIR"
}

# Generate temporary self-signed certificate if none exists
generate_certificate() {
    local cert_path="$STUNNEL_DIR/stunnel5.pem"

    if [ ! -f "$CERT_DIR/fullchain.pem" ] || [ ! -f "$CERT_DIR/privkey.pem" ]; then
        openssl req -new -x509 -days 365 -nodes \
            -out "$cert_path" \
            -keyout "$cert_path" \
            -subj "/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=localhost"
        chmod 600 "$cert_path"
    fi
}

# Configure Stunnel
configure_stunnel() {
    # Create Stunnel configuration
    cat >"$STUNNEL_DIR/stunnel5.conf" <<EOL
# Stunnel Configuration
pid = /var/run/stunnel5.pid
cert = ${CERT_DIR}/fullchain.pem
key = ${CERT_DIR}/privkey.pem
client = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
TIMEOUTclose = 0

# SSL/TLS Configuration
sslVersion = TLSv1.2
ciphers = ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305
options = NO_SSLv2
options = NO_SSLv3
options = NO_TLSv1
options = NO_TLSv1.1
options = SINGLE_ECDH_USE
options = CIPHER_SERVER_PREFERENCE

# Performance Tuning
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
compression = no
delay = no

# Security Options
chroot = /var/run/stunnel5/
setuid = stunnel
setgid = stunnel
debug = 0

[dropbear]
accept = 445
connect = 127.0.0.1:109

[openssh]
accept = 444
connect = 127.0.0.1:22

[openvpn]
accept = 990
connect = 127.0.0.1:1194
EOL
    chmod 600 "$STUNNEL_DIR/stunnel5.conf"
}

# Install Stunnel from source
install_stunnel() {
    cd /tmp
    wget "$STUNNEL_SOURCE"
    tar xzf "stunnel-${STUNNEL_VERSION}.tar.gz"
    cd "stunnel-${STUNNEL_VERSION}"

    # Configure with security options
    ./configure \
        --prefix=/usr/local \
        --with-ssl=/usr/include/openssl \
        --disable-libwrap \
        --disable-systemd \
        --with-threads=pthread

    make
    make install

    # Create stunnel user and group
    groupadd -r stunnel
    useradd -r -g stunnel -d /var/run/stunnel5 -s /bin/false stunnel

    # Create required directories
    mkdir -p /var/run/stunnel5
    chown stunnel:stunnel /var/run/stunnel5
    chmod 700 /var/run/stunnel5

    # Create systemd service
    cat >/etc/systemd/system/stunnel5.service <<EOL
[Unit]
Description=Stunnel5 SSL Tunnel
Documentation=https://www.stunnel.org
After=network.target
After=syslog.target

[Service]
Type=forking
ExecStart=/usr/local/bin/stunnel ${STUNNEL_DIR}/stunnel5.conf
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/var/run/stunnel5.pid
Restart=always
RestartSec=5
LimitNOFILE=65535
User=root

[Install]
WantedBy=multi-user.target
EOL
}

# Setup firewall rules
configure_firewall() {
    # Allow Stunnel ports
    if command -v ufw >/dev/null; then
        ufw allow 444/tcp
        ufw allow 445/tcp
        ufw allow 990/tcp
    fi
}

# Main installation function
main() {
    # Install dependencies
    install_dependencies

    # Setup directories
    setup_directories

    # Generate temporary certificate if needed
    generate_certificate

    # Configure Stunnel
    configure_stunnel

    # Install Stunnel
    install_stunnel

    # Configure firewall
    configure_firewall

    # Start service
    systemctl daemon-reload
    systemctl enable stunnel5
    systemctl start stunnel5

    # Cleanup
    rm -rf /tmp/stunnel-${STUNNEL_VERSION}*

    clear
}

# Run installation
main
