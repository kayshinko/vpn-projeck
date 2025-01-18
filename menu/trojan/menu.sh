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
TROJAN_DB="$SCRIPT_DIR/config/xray/trojan-users.db"
MENU_DIR="$SCRIPT_DIR/menu/trojan"

# Function clear screen
clear_screen() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Trojan User Management"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
}

# Function untuk menampilkan menu
show_menu() {
    clear_screen
    echo -e "Trojan Service Information:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e " • Status Xray : $(systemctl is-active xray)"
    echo -e " • Trojan Port : $(grep -m 1 '"port":' $SCRIPT_DIR/config/xray/trojan.json | cut -d':' -f2 | tr -d ' ,')"
    echo -e " • Total Trojan Users : $(grep -c "^### " "$TROJAN_DB" 2>/dev/null || echo "0")"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "Menu Options:"
    echo -e " [1] Add Trojan User"
    echo -e " [2] Delete Trojan User"
    echo -e " [3] Extend Trojan User"
    echo -e " [4] List Trojan Users"
    echo -e " [5] Monitor Trojan Connections"
    echo -e " [6] Change Trojan Port"
    echo -e " [7] Back to Main Menu"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select menu [1-7]: " menu_option
}

# Function untuk menambah user Trojan
add_user() {
    bash "$MENU_DIR/add.sh"
}

# Function untuk menghapus user Trojan
delete_user() {
    bash "$MENU_DIR/del.sh"
}

# Function untuk extend user Trojan
extend_user() {
    bash "$MENU_DIR/extend.sh"
}

# Function untuk list user Trojan
list_users() {
    bash "$MENU_DIR/list.sh"
}

# Function untuk monitor user Trojan
monitor_users() {
    echo -e "Current Trojan Connections:"
    echo -e "───────────────────────────────────────────────────────────"
    netstat -tnlp | grep xray
    echo -e "───────────────────────────────────────────────────────────"
    read -n 1 -s -r -p "Press any key to continue"
}

# Function untuk change Trojan port
change_port() {
    clear_screen
    echo -e "Current Trojan Port:"
    echo -e "───────────────────────────────────────────────────────────"
    netstat -tnlp | grep xray
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Enter new Trojan port [1-65535]: " new_port

    # Validate port number
    if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
        # Update Xray configuration
        sed -i "s/\"port\": [0-9]*/\"port\": $new_port/" "$SCRIPT_DIR/config/xray/trojan.json"

        # Restart Xray service
        systemctl restart xray

        echo -e "${GREEN}Trojan port changed to $new_port${NC}"
        echo -e "Please remember to update your client configurations"
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
