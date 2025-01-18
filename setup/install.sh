#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="/root/vpn/setup"
VPN_DIR="/root/vpn"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Function to log installation steps
log_step() {
    echo -e "${YELLOW}[INSTALL] $1${NC}"
    echo "$1" >>"$VPN_DIR/logs/install.log"
}

# Main installation function
install_vpn_system() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       VPN Management System Installation            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

    # Create necessary directories
    mkdir -p "$VPN_DIR"/{setup,menu,config,logs,cert}

    # Run dependency installation
    log_step "Installing system dependencies"
    bash "$SCRIPT_DIR/dependency.sh"

    # Install core components
    log_step "Installing SSH and Dropbear"
    bash "$SCRIPT_DIR/ssh.sh"

    log_step "Installing Stunnel5"
    bash "$SCRIPT_DIR/stunnel5.sh"

    log_step "Installing Nginx"
    bash "$SCRIPT_DIR/nginx.sh"

    log_step "Installing Xray Core"
    bash "$SCRIPT_DIR/xray.sh"

    log_step "Configuring SSL and Cloudflare"
    bash "$SCRIPT_DIR/ssl.sh"

    log_step "Configuring IP Whitelist"
    bash "$SCRIPT_DIR/ip.sh"

    # Set permissions
    chmod +x "$VPN_DIR/menu"/**/*.sh
    chmod +x "$VPN_DIR/setup"/*.sh

    # Final configuration
    log_step "Finalizing VPN Management System Configuration"

    # Create initial config files if they don't exist
    [ ! -f "$VPN_DIR/config/domain.conf" ] && echo "vpn.example.com" >"$VPN_DIR/config/domain.conf"

    # Restart services
    systemctl restart ssh
    systemctl restart dropbear
    systemctl restart nginx
    systemctl restart xray

    # Installation complete
    echo -e "${GREEN}VPN Management System Installation Complete!${NC}"
    echo -e "${YELLOW}Please configure your domain and SSL certificates.${NC}"
}

# Run the installation
install_vpn_system

# Optional: Run initial configuration menu
/root/vpn/menu/menu.sh
