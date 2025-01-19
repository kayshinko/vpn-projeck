#!/bin/bash
# Colors
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'

# Paths
SCRIPT_DIR="/usr/local/vpn"
TROJAN_DB="$SCRIPT_DIR/config/xray/trojan-users.db"
XRAY_CONFIG="$SCRIPT_DIR/config/xray/trojan.json"

# Set timezone to Asia/Jakarta
export TZ='Asia/Jakarta'

# Function to list Trojan users
list_trojan_users() {
    clear
    echo -e "${BLUE}╒═══════════════════════════════════════════════════════════╕${NC}"
    echo -e "${BLUE}║           Trojan Users List ($(date '+%Y-%m-%d %H:%M:%S %Z'))            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

    # Check if database exists
    if [[ ! -f "$TROJAN_DB" ]]; then
        echo -e "${RED}Trojan user database not found!${NC}"
        return 1
    fi

    # Get Trojan port
    port=$(grep '"port":' "$XRAY_CONFIG" | cut -d':' -f2 | tr -d ' ,')

    # Print header
    printf "${YELLOW}%-20s %-20s %-15s %-15s %-15s${NC}\n" "Username" "Password" "Expiration" "Max Login" "Status"
    echo "────────────────────────────────────────────────────────────────────────────────"

    # Process each user
    total_users=0
    while read -r line; do
        # Skip empty or comment lines
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Extract user details
        username=$(echo "$line" | awk '{print $2}')
        exp_date=$(echo "$line" | awk '{print $3}')
        password=$(echo "$line" | awk '{print $4}')
        # Default to 2 if no limit is stored
        max_login=$(echo "$line" | awk '{print $5 ? $5 : 2}')

        # Calculate days remaining
        days_remaining=$((($(date -d "$exp_date" +%s) - $(date +%s)) / 86400))

        # Determine status
        if [[ "$days_remaining" -lt 0 ]]; then
            status="${RED}Expired${NC}"
            status_color=$RED
        elif [[ "$days_remaining" -le 3 ]]; then
            status="${YELLOW}Expiring Soon${NC}"
            status_color=$YELLOW
        else
            status="${GREEN}Active${NC}"
            status_color=$GREEN
        fi

        # Print user details
        printf "%-20s %-20s %-15s %-15s ${status_color}%-15s${NC}\n" \
            "$username" "$password" "$exp_date" "$max_login" "$status"

        ((total_users++))
    done < <(grep "^### " "$TROJAN_DB")

    # Footer
    echo "────────────────────────────────────────────────────────────────────────────────"

    # Additional system info
    echo -e "\n${YELLOW}System Information:${NC}"
    echo -e " Trojan Port      : $port"
    echo -e " Current Date/Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo -e " Total Trojan Users: $total_users"

    # Detailed summary
    active_users=$(grep "^### " "$TROJAN_DB" | awk '{exp=$3; days=((strftime("%s", exp) - systime()) / 86400)} days > 0' | wc -l)
    expiring_users=$(grep "^### " "$TROJAN_DB" | awk '{exp=$3; days=((strftime("%s", exp) - systime()) / 86400)} days > 0 && days <= 3' | wc -l)
    expired_users=$((total_users - active_users))

    echo -e "\n${YELLOW}User Status Summary:${NC}"
    echo -e " Active Users      : ${GREEN}$active_users${NC}"
    echo -e " Expiring Users    : ${YELLOW}$expiring_users${NC}"
    echo -e " Expired Users     : ${RED}$expired_users${NC}"

    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
list_trojan_users
