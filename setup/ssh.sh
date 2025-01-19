#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
VPN_DIR="/usr/local/vpn"
CONFIG_DIR="$VPN_DIR/config"
SSH_DB="$CONFIG_DIR/ssh-users.db"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Install required packages
install_packages() {
    apt-get update -y
    apt-get install -y openssh-server dropbear fail2ban ufw

    # Install additional security tools
    apt-get install -y \
        libpam-pwquality \
        auditd \
        acct \
        tree \
        net-tools
}

# Configure SSH security settings
configure_ssh() {
    # Backup original SSH config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # Create optimized SSH configuration
    cat >/etc/ssh/sshd_config <<EOL
# Basic SSH Configuration
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Security
PermitRootLogin yes
MaxAuthTries 3
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Authentication
LoginGraceTime 30
StrictModes yes
MaxStartups 10:30:60

# Environment
AcceptEnv LANG LC_*
X11Forwarding no
PrintMotd no
Banner /etc/ssh/banner

# Keepalive
ClientAliveInterval 60
ClientAliveCountMax 3

# Security Features
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
DebianBanner no
EOL

    # Create SSH banner
    cat >/etc/ssh/banner <<EOL
******************************************
*     Authorized Access Only!            *
*     All activities are monitored       *
*     and recorded                       *
******************************************
EOL

    # Setup SSH directory permissions
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
}

# Configure Dropbear settings
configure_dropbear() {
    # Backup original config
    cp /etc/default/dropbear /etc/default/dropbear.bak

    # Configure Dropbear
    cat >/etc/default/dropbear <<EOL
# Dropbear Configuration
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143 -w -g"
DROPBEAR_BANNER="/etc/ssh/banner"
DROPBEAR_RECEIVE_WINDOW=65536
EOL

    # Create Dropbear directory
    mkdir -p /etc/dropbear

    # Generate keys if they don't exist
    if [ ! -f "/etc/dropbear/dropbear_rsa_host_key" ]; then
        dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
    fi
    if [ ! -f "/etc/dropbear/dropbear_ecdsa_host_key" ]; then
        dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key
    fi
}

# Configure fail2ban
configure_fail2ban() {
    # Create fail2ban SSH configuration
    cat >/etc/fail2ban/jail.local <<EOL
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

[dropbear]
enabled = true
port = 109,143
filter = dropbear
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOL

    systemctl enable fail2ban
    systemctl restart fail2ban
}

# Configure UFW firewall
configure_firewall() {
    # Enable UFW
    ufw default deny incoming
    ufw default allow outgoing

    # Allow SSH ports
    ufw allow 22/tcp
    ufw allow 109/tcp
    ufw allow 143/tcp

    # Allow common VPN ports
    ufw allow 80/tcp
    ufw allow 443/tcp

    # Enable firewall
    echo "y" | ufw enable
}

# Setup SSH user database
setup_ssh_database() {
    # Create config directory with secure permissions
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"

    # Create and secure SSH users database
    touch "$SSH_DB"
    chmod 600 "$SSH_DB"

    # Create basic database structure
    cat >"$SSH_DB" <<EOL
# SSH Users Database
# Format: username:password:exp_date:created_date
# Example: user1:hashedpass:2024-12-31:2024-01-01
EOL
}

# Configure audit logging
configure_audit() {
    # Enable process accounting
    accton on

    # Configure audit rules
    cat >/etc/audit/rules.d/audit.rules <<EOL
# Log all commands run as root
-a exit,always -F arch=b64 -F euid=0 -S execve
# Log SSH related events
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /etc/ssh/banner -p wa -k ssh_banner
EOL

    systemctl enable auditd
    systemctl restart auditd
}

# Main installation function
main() {
    install_packages
    configure_ssh
    configure_dropbear
    configure_fail2ban
    configure_firewall
    setup_ssh_database
    configure_audit

    # Restart services
    systemctl restart ssh dropbear fail2ban
    systemctl enable ssh dropbear fail2ban

    clear
}

# Run installation
main
