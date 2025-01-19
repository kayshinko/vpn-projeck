#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
NC='\033[0m'

# Paths
VPN_DIR="/usr/local/vpn"
CONFIG_DIR="$VPN_DIR/config"
SSH_DB="$CONFIG_DIR/ssh-users.db"
MENU_DIR="$VPN_DIR/menu/ssh"

# Get service ports
get_port() {
    case $1 in
    "ssh") port=$(grep -E "^Port" /etc/ssh/sshd_config | awk '{print $2}') ;;
    "dropbear") port=$(grep -E "^DROPBEAR_PORTS" /etc/default/dropbear | cut -d '=' -f2) ;;
    "stunnel") port=$(grep "accept" $CONFIG_DIR/stunnel5/stunnel5.conf | head -1 | awk '{print $3}') ;;
    esac
    echo $port
}

# Get service status with colored output
get_status() {
    if systemctl is-active --quiet $1; then
        echo -e "${GREEN}Active${NC}"
    else
        echo -e "${RED}Inactive${NC}"
    fi
}

# Get active connections
get_connections() {
    echo $(who | grep -c pts/)
}

# Get total users
get_total_users() {
    echo $(grep -c "^###" "$SSH_DB" 2>/dev/null || echo "0")
}

# Display header
show_header() {
    clear
    echo -e "${BLUE}╔═════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    SSH User Management                       ║${NC}"
    echo -e "${BLUE}╚═════════════════════════════════════════════════════════════╝${NC}"
}

# Display service information
show_service_info() {
    echo -e "\n${YELLOW}Service Status:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    printf " %-12s : %-20s  Port: %-15s\n" "SSH" "$(get_status ssh)" "$(get_port ssh)"
    printf " %-12s : %-20s  Port: %-15s\n" "Dropbear" "$(get_status dropbear)" "$(get_port dropbear)"
    printf " %-12s : %-20s  Port: %-15s\n" "Stunnel" "$(get_status stunnel5)" "$(get_port stunnel)"
    echo -e "└─────────────────────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}User Statistics:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    echo -e " Active Connections : $(get_connections)"
    echo -e " Total Users       : $(get_total_users)"
    echo -e "└─────────────────────────────────────────────────────────────┘"
}

# Display menu options
show_menu() {
    echo -e "\n${YELLOW}Menu Options:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    echo -e " [${GREEN}1${NC}] Add SSH User        [${GREEN}5${NC}] Monitor SSH Users"
    echo -e " [${GREEN}2${NC}] Delete SSH User     [${GREEN}6${NC}] Change SSH Port"
    echo -e " [${GREEN}3${NC}] Extend SSH User     [${GREEN}7${NC}] View SSH Log"
    echo -e " [${GREEN}4${NC}] List SSH Users      [${GREEN}8${NC}] Back to Main Menu"
    echo -e "└─────────────────────────────────────────────────────────────┘"
}

# Monitor active connections
monitor_connections() {
    show_header
    echo -e "\n${YELLOW}Active SSH Connections:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    who
    echo -e "└─────────────────────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}Network Connections:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    netstat -tnlp | grep -E ':22|:143|:109|:443'
    echo -e "└─────────────────────────────────────────────────────────────┘"

    read -n 1 -s -r -p "Press any key to continue"
}

# Change SSH port
change_ssh_port() {
    show_header
    echo -e "\n${YELLOW}Current SSH Port Configuration:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    netstat -tnlp | grep -E ':22|:143|:109|:443'
    echo -e "└─────────────────────────────────────────────────────────────┘"

    read -p "Enter new SSH port [1-65535]: " new_port

    if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
        # Backup config
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

        # Update port
        sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config

        # Update firewall
        if command -v ufw >/dev/null; then
            ufw allow $new_port/tcp
        fi

        # Restart service
        systemctl restart ssh

        echo -e "${GREEN}SSH port updated to $new_port${NC}"
    else
        echo -e "${RED}Invalid port number${NC}"
    fi

    read -n 1 -s -r -p "Press any key to continue"
}

# View SSH logs
view_ssh_log() {
    show_header
    echo -e "\n${YELLOW}Recent SSH Access Log:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    tail -n 50 /var/log/auth.log | grep -i ssh
    echo -e "└─────────────────────────────────────────────────────────────┘"
    read -n 1 -s -r -p "Press any key to continue"
}

# Main menu loop
while true; do
    show_header
    show_service_info
    show_menu

    read -p "Select menu [1-8]: " menu_option

    case $menu_option in
    1) bash "$MENU_DIR/add.sh" ;;
    2) bash "$MENU_DIR/del.sh" ;;
    3) bash "$MENU_DIR/extend.sh" ;;
    4) bash "$MENU_DIR/list.sh" ;;
    5) monitor_connections ;;
    6) change_ssh_port ;;
    7) view_ssh_log ;;
    8) break ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        sleep 1
        ;;
    esac
done

clear
