#!/bin/bash
# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure vnstat is installed
if ! command -v vnstat &>/dev/null; then
    echo -e "${YELLOW}Installing vnstat...${NC}"
    apt-get update
    apt-get install -y vnstat
    systemctl enable vnstat
    systemctl start vnstat
fi

# Bandwidth monitoring function
monitor_bandwidth() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Bandwidth Monitor"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Get default network interface
    default_interface=$(ip route | grep default | awk '{print $5}' | head -n 1)

    # Check if interface exists
    if [ -z "$default_interface" ]; then
        echo -e "${RED}No active network interface found!${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    # Bandwidth monitoring options
    echo -e "Monitoring Options:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e " [1] Today's Bandwidth Usage"
    echo -e " [2] Monthly Bandwidth Usage"
    echo -e " [3] Top 5 Days Bandwidth Usage"
    echo -e " [4] Live Bandwidth Monitor"
    echo -e " [5] Back to Menu"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select an option [1-5]: " bandwidth_option

    case $bandwidth_option in
    1)
        # Today's bandwidth
        echo -e "\n${BLUE}Today's Bandwidth Usage:${NC}"
        vnstat -i "$default_interface" -d
        ;;

    2)
        # Monthly bandwidth
        echo -e "\n${BLUE}Monthly Bandwidth Usage:${NC}"
        vnstat -i "$default_interface" -m
        ;;

    3)
        # Top 5 days
        echo -e "\n${BLUE}Top 5 Days Bandwidth Usage:${NC}"
        vnstat -i "$default_interface" -d -t 5
        ;;

    4)
        # Live bandwidth monitor
        echo -e "\n${BLUE}Live Bandwidth Monitor (Press CTRL+C to exit):${NC}"
        # Use iftop if available, otherwise use vnstat live
        if command -v iftop &>/dev/null; then
            sudo iftop -i "$default_interface"
        else
            echo -e "${YELLOW}Installing iftop for live monitoring...${NC}"
            apt-get install -y iftop
            sudo iftop -i "$default_interface"
        fi
        ;;

    5)
        return 0
        ;;

    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
    esac

    read -n 1 -s -r -p "Press any key to continue"
}

# Run the function
monitor_bandwidth
