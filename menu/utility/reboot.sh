#!/bin/bash
# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function untuk reboot
reboot_system() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " System Reboot"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Check current load and uptime
    echo -e "${YELLOW}Current System Status:${NC}"
    echo -e "Uptime: $(uptime -p)"
    echo -e "Load Average: $(uptime | awk -F'[, ]' '{print $10, $11, $12}')"

    # Confirm reboot
    echo -e "\n${RED}WARNING: This will restart the entire system!${NC}"
    read -p "Are you sure you want to reboot? [y/N]: " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Stop critical services gracefully
        echo -e "\n${YELLOW}Stopping services...${NC}"
        systemctl stop xray
        systemctl stop nginx
        systemctl stop ssh

        # Log reboot
        echo "System rebooted at $(date)" >>/root/vpn/logs/reboot.log

        # Countdown
        echo -e "${GREEN}Rebooting in:${NC}"
        for i in {5..1}; do
            echo -n "$i "
            sleep 1
        done

        # Reboot
        reboot
    else
        echo -e "${YELLOW}Reboot cancelled.${NC}"
        read -n 1 -s -r -p "Press any key to continue"
    fi
}

# Run reboot function
reboot_system
