#!/bin/bash
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
# Path
SCRIPT_DIR="/root/vpn"
TROJAN_DB="$SCRIPT_DIR/config/xray/trojan-users.db"
XRAY_CONFIG="$SCRIPT_DIR/config/xray/trojan.json"

# Set timezone to Asia/Jakarta
export TZ='Asia/Jakarta'

# Function untuk menampilkan daftar user Trojan
list_trojan_users() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Trojan Users List ($(date '+%Y-%m-%d %H:%M:%S %Z'))"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Check if database exists
    if [[ ! -f "$TROJAN_DB" ]]; then
        echo -e "${RED}Trojan user database not found!${NC}"
        return 1
    fi

    # Get Trojan port
    port=$(grep '"port":' "$XRAY_CONFIG" | cut -d':' -f2 | tr -d ' ,')

    # Print header
    printf "%-20s %-20s %-20s %-15s\n" "Username" "Password" "Expiration Date" "Status"
    echo "────────────────────────────────────────────────────────────────────────────────"

    # Process each user
    while read -r line; do
        # Skip empty or comment lines
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Extract username, expiration date, and password
        username=$(echo "$line" | awk '{print $2}')
        exp_date=$(echo "$line" | awk '{print $3}')
        password=$(echo "$line" | awk '{print $4}')

        # Calculate days remaining
        days_remaining=$((($(date -d "$exp_date" +%s) - $(date +%s)) / 86400))

        # Determine status
        if [[ "$days_remaining" -lt 0 ]]; then
            status="${RED}Expired${NC}"
        elif [[ "$days_remaining" -le 3 ]]; then
            status="${RED}Expiring Soon${NC}"
        else
            status="${GREEN}Active${NC}"
        fi

        # Print user details
        printf "%-20s %-20s %-20s %-15s\n" "$username" "$password" "$exp_date" "$status"

    done < <(grep "^### " "$TROJAN_DB")

    # Footer
    echo "────────────────────────────────────────────────────────────────────────────────"

    # Additional system info
    echo -e "\nTrojan Port: $port"
    echo -e "Current Date & Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo -e "Total Trojan Users: $(grep -c "^### " "$TROJAN_DB")"

    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
list_trojan_users
