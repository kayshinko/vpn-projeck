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
MENU_DIR="$VPN_DIR/menu"

# Load system information
load_system_info() {
    HOSTNAME=$(hostname)
    IPADDR=$(curl -s ipv4.icanhazip.com)
    ISP=$(curl -s ipinfo.io/org | tr -d '"')
    CITY=$(curl -s ipinfo.io/city | tr -d '"')
    TIMEZONE=$(curl -s ipinfo.io/timezone | tr -d '"')
    UPTIME=$(uptime -p | cut -d " " -f 2-10)
    OS=$(. /etc/os-release && echo "$PRETTY_NAME")
    KERNEL=$(uname -r)
    MEMORY=$(free -m | awk 'NR==2{printf "%.2f/%.2f GB (%.2f%%)", $3/1024, $2/1024, $3*100/$2}')
    DISK=$(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}')
    CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.1f%%", $2}')
    DOMAIN=$(cat $CONFIG_DIR/domain.conf 2>/dev/null || echo 'Not Set')
}

# Check service status
status_service() {
    if systemctl is-active --quiet $1; then
        echo -e "${GREEN}●${NC}"
    else
        echo -e "${RED}●${NC}"
    fi
}

# Get service port
get_service_port() {
    case $1 in
    "ssh") port=$(grep -E "^Port" /etc/ssh/sshd_config | awk '{print $2}') ;;
    "dropbear") port=$(grep -E "^DROPBEAR_PORT" /etc/default/dropbear | cut -d '=' -f2) ;;
    "stunnel") port=$(grep "accept" $CONFIG_DIR/stunnel5/stunnel5.conf | head -1 | awk '{print $3}') ;;
    "xray") port=$(grep -A1 '"port":' /etc/xray/config.json | tail -1 | tr -d ', ' | awk '{print $1}') ;;
    *) port="N/A" ;;
    esac
    echo $port
}

# Display header
show_header() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║               VPN Management System                        ║${NC}"
    echo -e "${BLUE}║           $(date '+%Y-%m-%d %H:%M:%S')                    ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
}

# Display system information
show_system_info() {
    load_system_info
    echo -e "\n${YELLOW}System Information:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────┐"
    echo -e " OS Version    : $OS"
    echo -e " Kernel       : $KERNEL"
    echo -e " IP Address   : $IPADDR"
    echo -e " ISP          : $ISP"
    echo -e " Location     : $CITY"
    echo -e " Domain       : $DOMAIN"
    echo -e " CPU Load     : $CPU_LOAD"
    echo -e " Memory Usage : $MEMORY"
    echo -e " Disk Usage   : $DISK"
    echo -e " Uptime      : $UPTIME"
    echo -e "└─────────────────────────────────────────────────────────┘"
}

# Display service status
show_service_status() {
    echo -e "\n${YELLOW}Service Status:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────┐"
    printf " %-15s : %s  Port: %-10s\n" "SSH" "$(status_service ssh)" "$(get_service_port ssh)"
    printf " %-15s : %s  Port: %-10s\n" "Dropbear" "$(status_service dropbear)" "$(get_service_port dropbear)"
    printf " %-15s : %s  Port: %-10s\n" "Stunnel5" "$(status_service stunnel5)" "$(get_service_port stunnel)"
    printf " %-15s : %s  Port: %-10s\n" "Xray" "$(status_service xray)" "$(get_service_port xray)"
    printf " %-15s : %s\n" "Nginx" "$(status_service nginx)"
    echo -e "└─────────────────────────────────────────────────────────┘"
}

# Display menu options
show_menu_options() {
    echo -e "\n${YELLOW}Menu Options:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────┐"
    echo -e " [${GREEN}1${NC}] SSH Menu          [${GREEN}5${NC}] Utility Menu"
    echo -e " [${GREEN}2${NC}] VMess Menu        [${GREEN}6${NC}] Monitor Menu"
    echo -e " [${GREEN}3${NC}] VLess Menu        [${GREEN}7${NC}] Settings"
    echo -e " [${GREEN}4${NC}] Trojan Menu       [${GREEN}8${NC}] Exit"
    echo -e "└─────────────────────────────────────────────────────────┘"
}

# Execute menu option
execute_menu() {
    case $1 in
    1) bash $MENU_DIR/ssh/menu.sh ;;
    2) bash $MENU_DIR/vmess/menu.sh ;;
    3) bash $MENU_DIR/vless/menu.sh ;;
    4) bash $MENU_DIR/trojan/menu.sh ;;
    5) bash $MENU_DIR/utility/menu.sh ;;
    6) bash $MENU_DIR/monitor/menu.sh ;;
    7) settings_menu ;;
    8)
        clear
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        sleep 1
        ;;
    esac
}

# Settings menu
settings_menu() {
    while true; do
        show_header
        echo -e "\n${YELLOW}Settings Menu:${NC}"
        echo -e "┌─────────────────────────────────────────────────────────┐"
        echo -e " [${GREEN}1${NC}] Change Domain"
        echo -e " [${GREEN}2${NC}] Change Port"
        echo -e " [${GREEN}3${NC}] Update Script"
        echo -e " [${GREEN}4${NC}] Back to Main Menu"
        echo -e "└─────────────────────────────────────────────────────────┘"

        read -p "Select option [1-4]: " settings_option
        case $settings_option in
        1) bash $MENU_DIR/utility/domain.sh ;;
        2) bash $MENU_DIR/utility/port.sh ;;
        3) bash $MENU_DIR/utility/update.sh ;;
        4) break ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
        esac
    done
}

# Main menu loop
while true; do
    show_header
    show_system_info
    show_service_status
    show_menu_options
    read -p "Select menu [1-8]: " menu_option
    execute_menu $menu_option
done
