#!/bin/bash
# Colors
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'

# Path
SCRIPT_DIR="/usr/local/vpn"
MENU_DIR="$SCRIPT_DIR/menu/utility"

# Function clear screen
clear_screen() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " VPN Management - Utility Tools"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
}

# Function untuk menampilkan menu
show_menu() {
    clear_screen
    echo -e "Utility Tools:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e " [1] System Backup"
    echo -e " [2] System Restore"
    echo -e " [3] Domain Management"
    echo -e " [4] System Reboot"
    echo -e " [5] Check System Information"
    echo -e " [6] Update VPN Scripts"
    echo -e " [7] Back to Main Menu"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select an option [1-7]: " menu_option
}

# Function untuk backup
backup_system() {
    bash "$MENU_DIR/backup.sh"
}

# Function untuk restore
restore_system() {
    bash "$MENU_DIR/restore.sh"
}

# Function untuk domain management
manage_domain() {
    bash "$MENU_DIR/domain.sh"
}

# Function untuk reboot
reboot_system() {
    bash "$MENU_DIR/reboot.sh"
}

# Function untuk system info
check_system_info() {
    clear_screen
    echo -e "${YELLOW}System Information:${NC}"
    echo -e "───────────────────────────────────────────────────────────"

    # Hostname
    echo -e "${BLUE}• Hostname:${NC} $(hostname)"

    # OS Information
    echo -e "${BLUE}• Operating System:${NC} $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"

    # Kernel
    echo -e "${BLUE}• Kernel:${NC} $(uname -r)"

    # Uptime
    echo -e "${BLUE}• Uptime:${NC} $(uptime -p)"

    # CPU Info
    echo -e "${BLUE}• CPU:${NC} $(lscpu | grep 'Model name' | sed -r 's/Model name:\s{1,}//g')"

    # Memory
    echo -e "${BLUE}• Memory:${NC} $(free -h | grep Mem | awk '{print $2 " Total, " $4 " Free"}')"

    # Disk Usage
    echo -e "${BLUE}• Disk Usage:${NC} $(df -h / | awk '/\// {print $5 " used, " $4 " free"}')"

    echo -e "───────────────────────────────────────────────────────────"
    read -n 1 -s -r -p "Press any key to continue"
}

# Function untuk update scripts
update_scripts() {
    clear_screen
    echo -e "${YELLOW}Updating VPN Management Scripts...${NC}"

    # Ensure git is installed
    apt-get update
    apt-get install -y git

    # Backup existing scripts
    backup_dir="/usr/local/vpn-backup-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r "$SCRIPT_DIR" "$backup_dir"

    # Placeholder for actual update mechanism
    # In a real scenario, this would pull from a git repository
    echo -e "${RED}Note: Actual update mechanism needs to be configured${NC}"
    echo -e "Backup created at: $backup_dir"

    read -n 1 -s -r -p "Press any key to continue"
}

# Main loop
while true; do
    show_menu
    case $menu_option in
    1) backup_system ;;
    2) restore_system ;;
    3) manage_domain ;;
    4) reboot_system ;;
    5) check_system_info ;;
    6) update_scripts ;;
    7) exit 0 ;;
    *)
        echo -e "${RED}Invalid option. Please try again.${NC}"
        sleep 2
        ;;
    esac
done
