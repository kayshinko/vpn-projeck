#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
VPN_DIR="/usr/local/vpn"
CONFIG_DIR="$VPN_DIR/config"
SSH_DB="$CONFIG_DIR/ssh-users.db"

# Set timezone
export TZ='Asia/Jakarta'

# Function to get service status with color
get_service_status() {
    local service=$1
    if systemctl is-active --quiet $service; then
        echo -e "${GREEN}Active${NC}"
    else
        echo -e "${RED}Inactive${NC}"
    fi
}

# Function to get user status and color
get_user_status() {
    local days=$1
    if [[ "$days" -lt 0 ]]; then
        echo -e "${RED}Expired ($days days)${NC}"
    elif [[ "$days" -le 3 ]]; then
        echo -e "${YELLOW}Expiring Soon ($days days)${NC}"
    else
        echo -e "${GREEN}Active ($days days)${NC}"
    fi
}

# Function to get logged in users
get_logged_users() {
    local username=$1
    echo "$(who | grep "^$username " | wc -l)"
}

# Function to convert bytes to human readable
convert_bytes() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$(((bytes + 512) / 1024))KB"
    else
        echo "$(((bytes + 524288) / 1048576))MB"
    fi
}

# Function to get bandwidth usage
get_bandwidth() {
    local username=$1
    local rx_bytes=$(iptables -nvx -L OUTPUT 2>/dev/null | grep "$username" | awk '{print $2}')
    local tx_bytes=$(iptables -nvx -L INPUT 2>/dev/null | grep "$username" | awk '{print $2}')
    echo "↓$(convert_bytes ${rx_bytes:-0}) ↑$(convert_bytes ${tx_bytes:-0})"
}

# Function to list SSH users
list_ssh_users() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                   SSH Users List                          ║${NC}"
    echo -e "${BLUE}║          $(date '+%Y-%m-%d %H:%M:%S %Z')                 ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

    if [[ ! -f "$SSH_DB" ]]; then
        echo -e "\n${RED}SSH user database not found!${NC}"
        return 1
    fi

    echo -e "\n${YELLOW}User Information:${NC}"
    echo -e "┌────────────────────────────────────────────────────────────────────┐"
    printf "%-15s %-15s %-15s %-15s %-15s\n" "Username" "Expiry Date" "Status" "Login" "Bandwidth"
    echo -e "├────────────────────────────────────────────────────────────────────┤"

    total_users=0
    active_users=0
    expired_users=0

    while read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue

        username=$(echo "$line" | awk '{print $2}')
        exp_date=$(echo "$line" | awk '{print $3}')
        days_remaining=$((($(date -d "$exp_date" +%s) - $(date +%s)) / 86400))
        login_count=$(get_logged_users "$username")
        bandwidth=$(get_bandwidth "$username")
        status=$(get_user_status "$days_remaining")

        printf "%-15s %-15s %-35s %-15s %-15s\n" \
            "$username" \
            "$exp_date" \
            "$status" \
            "$login_count" \
            "$bandwidth"

        ((total_users++))
        [[ "$days_remaining" -ge 0 ]] && ((active_users++)) || ((expired_users++))
    done < <(grep "^### " "$SSH_DB")

    echo -e "└────────────────────────────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}System Information:${NC}"
    echo -e "┌────────────────────────────────────────────────────────────────────┐"
    echo -e " Date & Time     : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo -e " Total Users     : $total_users (${GREEN}$active_users Active${NC}, ${RED}$expired_users Expired${NC})"
    echo -e " Active Sessions : $(who | grep -c pts)"
    echo -e " Load Average    : $(uptime | awk -F'load average:' '{print $2}' | xargs)"
    echo -e " Memory Usage    : $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')"
    echo -e "└────────────────────────────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}Service Status:${NC}"
    echo -e "┌────────────────────────────────────────────────────────────────────┐"
    echo -e " SSH        : $(get_service_status ssh)"
    echo -e " Dropbear   : $(get_service_status dropbear)"
    echo -e " Stunnel    : $(get_service_status stunnel5)"
    echo -e " OpenVPN    : $(get_service_status openvpn)"
    echo -e "└────────────────────────────────────────────────────────────────────┘"

    echo -e "\nPress ${GREEN}[Enter]${NC} to continue"
    read
}

# Run function
list_ssh_users
