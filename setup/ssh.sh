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

# SSH and Dropbear installation function
install_ssh_dropbear() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     SSH and Dropbear Installation                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

    # Update package lists
    echo -e "${YELLOW}Updating package lists...${NC}"
    apt-get update -y

    # Install OpenSSH
    echo -e "${YELLOW}Installing OpenSSH...${NC}"
    apt-get install -y openssh-server

    # Install Dropbear
    echo -e "${YELLOW}Installing Dropbear...${NC}"
    apt-get install -y dropbear

    # Configure SSH
    configure_ssh

    # Configure Dropbear
    configure_dropbear

    # Set up SSH database
    setup_ssh_database

    # Restart services
    restart_services
}

# Configure SSH settings
configure_ssh() {
    echo -e "${YELLOW}Configuring SSH settings...${NC}"

    # Backup original SSH config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # Modify SSH configuration
    sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config

    # Enable key authentication
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
}

# Configure Dropbear settings
configure_dropbear() {
    echo -e "${YELLOW}Configuring Dropbear settings...${NC}"

    # Modify Dropbear configuration
    sed -i 's/^NO_START=1/NO_START=0/' /etc/default/dropbear

    # Set Dropbear ports
    DROPBEAR_OPTS="-p 109 -p 143"
    sed -i "s/^DROPBEAR_OPTS=.*/DROPBEAR_OPTS=\"$DROPBEAR_OPTS\"/" /etc/default/dropbear
}

# Set up SSH user database
setup_ssh_database() {
    echo -e "${YELLOW}Setting up SSH user database...${NC}"

    # Create SSH database directory
    mkdir -p /root/vpn/config

    # Create or clear SSH users database
    touch /root/vpn/config/ssh-users.db
    chmod 600 /root/vpn/config/ssh-users.db
}

# Restart SSH services
restart_services() {
    echo -e "${YELLOW}Restarting SSH services...${NC}"

    # Restart OpenSSH
    systemctl restart ssh

    # Restart Dropbear
    systemctl restart dropbear

    # Enable services to start on boot
    systemctl enable ssh
    systemctl enable dropbear
}

# Run the installation
install_ssh_dropbear

# Verify installation
echo -e "${GREEN}SSH and Dropbear installation complete!${NC}"
echo -e "${YELLOW}SSH Ports:${NC} 22"
echo -e "${YELLOW}Dropbear Ports:${NC} 109, 143"
