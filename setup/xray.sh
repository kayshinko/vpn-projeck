#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Xray installation parameters
XRAY_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
ARCH=$(uname -m)

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Architecture mapping
get_arch() {
    case "$ARCH" in
    x86_64) echo "64" ;;
    amd64) echo "64" ;;
    arm64) echo "arm64-v8a" ;;
    arm) echo "arm32-v6a" ;;
    *)
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
    esac
}

# Download and install Xray
install_xray() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║             Xray Core Installation                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

    # Create directories
    mkdir -p /usr/local/share/xray /etc/xray /root/vpn/config/xray

    # Determine architecture
    XRAY_ARCH=$(get_arch)

    # Download Xray
    echo -e "${YELLOW}Downloading Xray Core v${XRAY_VERSION} for ${XRAY_ARCH}...${NC}"
    wget -O xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip"

    # Unzip Xray
    unzip xray.zip -d /usr/local/share/xray
    chmod +x /usr/local/share/xray/xray

    # Create symlink
    ln -sf /usr/local/share/xray/xray /usr/bin/xray

    # Create systemd service
    create_systemd_service

    # Create initial configuration files
    create_config_files

    # Clean up
    rm xray.zip
}

# Create Systemd Service
create_systemd_service() {
    echo -e "${YELLOW}Creating Xray systemd service...${NC}"

    cat >/etc/systemd/system/xray.service <<EOL
[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/share/xray/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemd, enable and start Xray
    systemctl daemon-reload
    systemctl enable xray
    systemctl start xray
}

# Create Initial Configuration Files
create_config_files() {
    echo -e "${YELLOW}Creating Xray configuration files...${NC}"

    # Main Xray config (minimal)
    cat >/etc/xray/config.json <<EOL
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOL

    # Copy default protocol configs
    cp /root/vpn/config/xray/vmess.json /etc/xray/vmess.json
    cp /root/vpn/config/xray/vless.json /etc/xray/vless.json
    cp /root/vpn/config/xray/trojan.json /etc/xray/trojan.json
}

# Verify installation
verify_installation() {
    if systemctl is-active --quiet xray; then
        echo -e "${GREEN}Xray Core installed and running successfully!${NC}"
        xray version
    else
        echo -e "${RED}Failed to start Xray service${NC}"
        exit 1
    fi
}

# Main installation process
main() {
    install_xray
    verify_installation
}

# Run main function
main
