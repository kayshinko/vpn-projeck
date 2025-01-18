#!/bin/bash

# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'

# Path
SCRIPT_DIR="/root/vpn"
SSH_DB="$SCRIPT_DIR/config/ssh-users.db"
MENU_DIR="$SCRIPT_DIR/menu/ssh"

# Function clear screen
clear_screen() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e "                     SSH User Management"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
}

# Function untuk menampilkan menu
show_menu() {
    clear_screen
    echo -e "SSH Service Information:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "  • Status SSH      : $(systemctl is-active ssh)"
    echo -e "  • Status Dropbear : $(systemctl is-active dropbear)"
    echo -e "  • Status Stunnel  : $(systemctl is-active stunnel5)"
    echo -e "  • SSH Port        : 22, 143"
    echo -e "  • Dropbear Port   : 109, 443"
    echo -e "  • Active Users    : $(who | grep -c pts)"
    echo -e "  • Total Users     : $(grep -c "^###" "$SSH_DB" 2>/dev/null || echo "0")"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "Menu Options:"
    echo -e " [1] Add SSH User"
    echo -e " [2] Delete SSH User"
    echo -e " [3] Extend SSH User"
    echo -e " [4] List SSH Users"
    echo -e " [5] Monitor SSH Users"
    echo -e " [6] Change SSH Port"
    echo -e " [7] Back to Main Menu"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select menu [1-7]: " menu_option
}

# Function untuk menambah user SSH
add_user() {
    bash "$MENU_DIR/add.sh"
}

# Function untuk menghapus user SSH
delete_user() {
    bash "$MENU_DIR/del.sh"
}

# Function untuk extend user SSH
extend_user() {
    bash "$MENU_DIR/extend.sh"
}

# Function untuk list user SSH
list_users() {
    bash "$MENU_DIR/list.sh"
}

# Function untuk monitor user SSH
monitor_users() {
    echo -e "Current SSH Connections:"
    echo -e "───────────────────────────────────────────────────────────"
    who
    echo -e "───────────────────────────────────────────────────────────"
    netstat -tnlp | grep -E ':22|:143|:109|:443'
    echo -e "───────────────────────────────────────────────────────────"
    read -n 1 -s -r -p "Press any key to continue"
}

# Function untuk change SSH port
change_port() {
    clear_screen
    echo -e "Current SSH Ports:"
    echo -e "───────────────────────────────────────────────────────────"
    netstat -tnlp | grep -E ':22|:143|:109|:443'
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Enter new SSH port [1-65535]: " new_port

    # Validate port number
    if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
        # Backup sshd_config
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

        # Change port
        sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config

        # Restart SSH service
        systemctl restart ssh

        echo -e "${GREEN}SSH port changed to $new_port${NC}"
        echo -e "Please remember to update your firewall rules"
    else
        echo -e "${RED}Invalid port number${NC}"
    fi

    read -n 1 -s -r -p "Press any key to continue"
}

# Main loop
while true; do
    show_menu
    case $menu_option in
    1) add_user ;;
    2) delete_user ;;
    3) extend_user ;;
    4) list_users ;;
    5) monitor_users ;;
    6) change_port ;;
    7) exit 0 ;;
    *)
        echo -e "${RED}Please enter valid option${NC}"
        sleep 2
        ;;
    esac
done
