#!/bin/bash
# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to monitor CPU and RAM
monitor_system() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " System Resource Monitor"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Monitoring options
    echo -e "Monitoring Options:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e " [1] Overview System Resources"
    echo -e " [2] Detailed CPU Information"
    echo -e " [3] Memory Usage Breakdown"
    echo -e " [4] Top Resource-Consuming Processes"
    echo -e " [5] Real-time Monitor (htop)"
    echo -e " [6] Back to Menu"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select an option [1-6]: " system_option

    case $system_option in
    1)
        # System resources overview
        echo -e "\n${BLUE}System Resources Overview:${NC}"
        echo -e "${YELLOW}CPU Usage:${NC}"
        top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4 "%"}'

        echo -e "\n${YELLOW}Memory Usage:${NC}"
        free -h

        echo -e "\n${YELLOW}Disk Usage:${NC}"
        df -h /
        ;;

    2)
        # Detailed CPU Information
        echo -e "\n${BLUE}Detailed CPU Information:${NC}"
        lscpu | grep -E "Model name|Socket|Core|Thread"

        echo -e "\n${YELLOW}Per-Core CPU Usage:${NC}"
        mpstat -P ALL 1 1
        ;;

    3)
        # Detailed Memory Information
        echo -e "\n${BLUE}Memory Usage Breakdown:${NC}"
        free -h

        echo -e "\n${YELLOW}Memory Usage by Process:${NC}"
        ps aux | awk '{print $4 "% " $11}' | sort -rn | head -10
        ;;

    4)
        # Top resource-consuming processes
        echo -e "\n${BLUE}Top Resource-Consuming Processes:${NC}"
        echo -e "${YELLOW}By CPU Usage:${NC}"
        ps aux | sort -rn -k3 | head -10

        echo -e "\n${YELLOW}By Memory Usage:${NC}"
        ps aux | sort -rn -k4 | head -10
        ;;

    5)
        # Real-time monitor with htop
        echo -e "\n${BLUE}Real-time System Monitor (Press Q to exit)${NC}"
        htop
        ;;

    6)
        return 0
        ;;

    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
    esac

    read -n 1 -s -r -p "Press any key to continue"
}

# Check and install required tools
install_monitoring_tools() {
    # List of required tools
    local tools=("sysstat" "htop")

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "${YELLOW}Installing $tool...${NC}"
            apt-get update
            apt-get install -y "$tool"
        fi
    done
}

# Install tools before running
install_monitoring_tools

# Run the function
monitor_system
