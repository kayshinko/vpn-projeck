#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="/usr/local/vpn/setup"
VPN_DIR="/usr/local/vpn"
MENU_DIR="/usr/local/bin"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Function to log installation steps
log_step() {
    echo -e "${YELLOW}[INSTALL] *$1*${NC}"
    echo "*$1*" >>"$VPN_DIR/logs/install.log"
}

# Function to secure permissions
secure_permissions() {
    local dir="$1"
    local type="$2"

    case $type in
    "scripts")
        find "$dir" -type f -name "*.sh" -exec chmod 500 {} \;
        ;;
    "configs")
        find "$dir" -type f -exec chmod 600 {} \;
        ;;
    "certs")
        find "$dir" -type f -exec chmod 400 {} \;
        ;;
    "dirs")
        find "$dir" -type d -exec chmod 700 {} \;
        ;;
    esac
}

# Function to configure shell RC file
configure_shell_rc() {
    local rc_file=""

    # Detect shell and RC file
    if [ -f "/root/.zshrc" ]; then
        rc_file="/root/.zshrc"
        log_step "Configuring zshrc"
    else
        rc_file="/root/.bashrc"
        log_step "Configuring bashrc"
    fi

    # Create menu alias function
    local menu_function='
# VPN Menu Function
vpn_menu() {
    clear
    /usr/local/bin/vpn
}
# Alias for menu
alias menu="vpn_menu"
# Auto-start VPN menu on login
if [ -z "$MENU_DISPLAYED" ]; then
    export MENU_DISPLAYED=1
    vpn_menu
fi'

    # Remove any existing menu configuration
    sed -i '/# VPN Menu Function/,/fi/d' "$rc_file"

    # Add new menu configuration
    echo "$menu_function" >>"$rc_file"

    # Create vpn command wrapper
    cat >"$MENU_DIR/vpn" <<'EOF'
#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    exit 1
fi
/usr/local/vpn/menu/menu.sh "$@"
EOF
    chmod 555 "$MENU_DIR/vpn"

    # Reload RC file
    source "$rc_file"
    log_step "Shell configuration updated"
}

# Main installation function
install_vpn_system() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║             VPN Management System Installation        ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

    # Create necessary directories with secure permissions
    echo -e "${YELLOW}Creating system directories...${NC}"
    mkdir -p "$VPN_DIR"/{setup,menu,config,logs,cert}
    secure_permissions "$VPN_DIR" "dirs"

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

    # Set secure permissions
    echo -e "${YELLOW}Setting secure permissions...${NC}"
    secure_permissions "$VPN_DIR/menu" "scripts"
    secure_permissions "$VPN_DIR/setup" "scripts"
    secure_permissions "$VPN_DIR/config" "configs"
    secure_permissions "$VPN_DIR/cert" "certs"

    # Configure shell RC file
    configure_shell_rc

    # Final configuration
    log_step "Finalizing VPN Management System Configuration"

    # Create initial config files if they don't exist
    [ ! -f "$VPN_DIR/config/domain.conf" ] && echo "vpn.example.com" >"$VPN_DIR/config/domain.conf"

    # Set immutable attribute on critical files
    echo -e "${YELLOW}Setting immutable attributes on critical files...${NC}"
    chattr +i "$VPN_DIR/setup"/*.sh
    chattr +i "$VPN_DIR/menu"/**/*.sh

    # Create status file
    echo "VPN scripts installed on $(date)" >"$VPN_DIR/.installed"
    chattr +i "$VPN_DIR/.installed"

    # Restart services
    systemctl restart ssh dropbear nginx xray

    # Installation complete
    echo -e "${GREEN}Installation Complete!${NC}"
    sleep 2
    clear
}

# Run the installation
install_vpn_system

# Start the menu immediately after installation
"$MENU_DIR/vpn"
