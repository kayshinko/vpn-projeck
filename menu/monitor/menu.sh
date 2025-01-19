#!/bin/bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Path
SCRIPT_DIR="/usr/local/vpn"
MENU_DIR="$SCRIPT_DIR/menu/monitor"

# Function clear screen
clear_screen() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " System Monitoring Tools"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
}

# Function untuk menampilkan menu
show_menu() {
    clear_screen
    echo -e "Monitoring Options:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e " [1] Bandwidth Monitor"
    echo -e " [2] CPU & RAM Usage"
    echo -e " [3] System Logs"
    echo -e " [4] Network Connections"
    echo -e " [5] Service Status"
    echo -e " [6] Real-time Process Monitor"
    echo -e " [7] Back to Main Menu"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select an option [1-7]: " menu_option
}

# Function untuk bandwidth monitor
bandwidth_monitor() {
    bash "$MENU_DIR/bandwidth.sh"
}

# Function untuk CPU & RAM monitor
cpu_monitor() {
    bash "$MENU_DIR/cpu.sh"
}

# Function untuk log viewer
log_viewer() {
    bash "$MENU_DIR/log.sh"
}

# Function untuk network connections
network_connections() {
    clear_screen
    echo -e "${BLUE}Active Network Connections:${NC}"
    echo -e "───────────────────────────────────────────────────────────"

    # TCP Connections
    echo -e "${YELLOW}TCP Connections:${NC}"
    ss -tunapo

    # Active Listening Ports
    echo -e "\n${YELLOW}Listening Ports:${NC}"
    netstat -tuln

    read -n 1 -s -r -p "Press any key to continue"
}

# Function untuk service status
service_status() {
    clear_screen
    echo -e "${BLUE}Critical Service Status:${NC}"
    echo -e "───────────────────────────────────────────────────────────"

    # List of services to check
    services=(
        "ssh"
        "nginx"
        "xray"
        "stunnel4"
    )

    for service in "${services[@]}"; do
        status=$(systemctl is-active "$service")
        if [ "$status" == "active" ]; then
            echo -e "${GREEN}$service:${NC} $status"
        else
            echo -e "${RED}$service:${NC} $status"
        fi
    done

    read -n 1 -s -r -p "Press any key to continue"
}

# Function untuk real-time process monitor
process_monitor() {
    clear_screen
    echo -e "${BLUE}Real-time Process Monitor (Press Q to quit)${NC}"
    echo -e "───────────────────────────────────────────────────────────"

    # Use htop for interactive process monitoring
    htop
}

# Main loop
while true; do
    show_menu
    case $menu_option in
    1) bandwidth_monitor ;;
    2) cpu_monitor ;;
    3) log_viewer ;;
    4) network_connections ;;
    5) service_status ;;
    6) process_monitor ;;
    7) exit 0 ;;
    *)
        echo -e "${RED}Invalid option. Please try again.${NC}"
        sleep 2
        ;;
    esac
done
