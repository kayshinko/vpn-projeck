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
CONFIG_DIR="$SCRIPT_DIR/config"
MENU_DIR="$SCRIPT_DIR/menu"

# Informasi Sistem
HOSTNAME=$(hostname)
IPADDR=$(curl -s ipv4.icanhazip.com)
ISP=$(curl -s ipinfo.io/org)
CITY=$(curl -s ipinfo.io/city)
WKT=$(curl -s ipinfo.io/timezone)
DATE=$(date +%Y-%m-%d)
UPTIME=$(uptime -p | cut -d " " -f 2-10)
OS=$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')

# Function untuk status service
status_service() {
    if systemctl is-active --quiet $1; then
        echo -e "${GREEN}ON${NC}"
    else
        echo -e "${RED}OFF${NC}"
    fi
}

# Function clear screen
clear_screen() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e "        Welcome to SMILANS VPN Manager - $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
}

# Function untuk menampilkan menu
show_menu() {
    clear_screen
    echo -e "System Information:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "  OS            : $OS"
    echo -e "  IP Address    : $IPADDR"
    echo -e "  ISP           : $ISP"
    echo -e "  City          : $CITY"
    echo -e "  Uptime        : $UPTIME"
    echo -e "  Domain        : $(cat $CONFIG_DIR/domain.conf 2>/dev/null || echo 'Not Set')"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "Service Status:"
    echo -e "  SSH           : $(status_service ssh)"
    echo -e "  Dropbear      : $(status_service dropbear)"
    echo -e "  Stunnel5      : $(status_service stunnel5)"
    echo -e "  Xray          : $(status_service xray)"
    echo -e "  Nginx         : $(status_service nginx)"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "Menu Options:"
    echo -e " [1] SSH Menu          [5] Utility Menu"
    echo -e " [2] VMess Menu        [6] Monitor Menu"
    echo -e " [3] VLess Menu        [7] Settings"
    echo -e " [4] Trojan Menu       [8] Exit"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select menu [1-8]: " menu_option
}

# Function untuk menjalankan menu
run_menu() {
    case $menu_option in
    1)
        bash $MENU_DIR/ssh/menu.sh
        ;;
    2)
        bash $MENU_DIR/vmess/menu.sh
        ;;
    3)
        bash $MENU_DIR/vless/menu.sh
        ;;
    4)
        bash $MENU_DIR/trojan/menu.sh
        ;;
    5)
        bash $MENU_DIR/utility/menu.sh
        ;;
    6)
        bash $MENU_DIR/monitor/menu.sh
        ;;
    7)
        settings_menu
        ;;
    8)
        echo -e "Thank you for using SMILANS VPN Manager"
        exit 0
        ;;
    *)
        echo -e "${RED}Please enter a valid option${NC}"
        sleep 2
        ;;
    esac
}

# Settings Menu
settings_menu() {
    clear_screen
    echo -e "Settings Menu:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e " [1] Change Domain"
    echo -e " [2] Change Port"
    echo -e " [3] Update Script"
    echo -e " [4] Back to Main Menu"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select option [1-4]: " settings_option

    case $settings_option in
    1)
        bash $MENU_DIR/utility/domain.sh
        ;;
    2)
        bash $MENU_DIR/utility/port.sh
        ;;
    3)
        bash $MENU_DIR/utility/update.sh
        ;;
    4)
        return
        ;;
    *)
        echo -e "${RED}Please enter a valid option${NC}"
        sleep 2
        settings_menu
        ;;
    esac
}

# Main Loop
while true; do
    show_menu
    run_menu
done
