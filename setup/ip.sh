#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
SCRIPT_DIR="/root/vpn"
WHITELIST_FILE="$SCRIPT_DIR/config/ip-whitelist.conf"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Function to display current whitelist
show_whitelist() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            IP Whitelist Configuration              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

    echo -e "${YELLOW}Current Whitelisted IPs:${NC}"
    grep -v "^#" "$WHITELIST_FILE" || echo "No IPs whitelisted"
}

# Function to add IP to whitelist
add_ip_to_whitelist() {
    read -p "Enter IP or CIDR to whitelist (e.g., 192.168.1.0/24): " new_ip

    # Validate IP/CIDR
    if [[ ! "$new_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/([0-9]|[1-2][0-9]|3[0-2]))?$ ]]; then
        echo -e "${RED}Invalid IP or CIDR format!${NC}"
        return 1
    fi

    # Check if IP already exists
    if grep -q "^$new_ip$" "$WHITELIST_FILE"; then
        echo -e "${YELLOW}IP/CIDR already in whitelist${NC}"
        return 1
    fi

    # Add IP to whitelist
    echo "$new_ip" >>"$WHITELIST_FILE"
    echo -e "${GREEN}IP/CIDR $new_ip added to whitelist${NC}"
}

# Function to remove IP from whitelist
remove_ip_from_whitelist() {
    show_whitelist

    read -p "Enter IP or CIDR to remove: " remove_ip

    # Remove IP from whitelist
    if sed -i "\|^$remove_ip$|d" "$WHITELIST_FILE"; then
        echo -e "${GREEN}IP/CIDR $remove_ip removed from whitelist${NC}"
    else
        echo -e "${RED}Failed to remove IP/CIDR${NC}"
    fi
}

# Function to apply whitelist using iptables
apply_whitelist() {
    # Flush existing rules
    iptables -F
    iptables -X

    # Default policy to drop
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    # Allow localhost
    iptables -A INPUT -i lo -j ACCEPT

    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Apply whitelist
    while read -r ip; do
        # Skip comments and empty lines
        [[ "$ip" =~ ^#|^$ ]] && continue

        # Allow whitelisted IPs
        iptables -A INPUT -s "$ip" -j ACCEPT
    done <"$WHITELIST_FILE"

    # Save iptables rules
    iptables-save >/etc/iptables/rules.v4

    echo -e "${GREEN}Whitelist rules applied successfully!${NC}"
}

# Main IP whitelist management function
ip_whitelist_management() {
    while true; do
        clear
        echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║            IP Whitelist Management               ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

        echo -e "Options:"
        echo -e " [1] Show Whitelist"
        echo -e " [2] Add IP/CIDR to Whitelist"
        echo -e " [3] Remove IP/CIDR from Whitelist"
        echo -e " [4] Apply Whitelist Rules"
        echo -e " [5] Back to Main Menu"

        read -p "Select an option [1-5]: " ip_option

        case $ip_option in
        1) show_whitelist ;;
        2) add_ip_to_whitelist ;;
        3) remove_ip_from_whitelist ;;
        4) apply_whitelist ;;
        5) break ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 2
            ;;
        esac

        read -n 1 -s -r -p "Press any key to continue..."
    done
}

# Ensure whitelist file exists
[ ! -f "$WHITELIST_FILE" ] && touch "$WHITELIST_FILE"

# Run IP whitelist management
ip_whitelist_management
