#!/bin/bash
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
# Path
SCRIPT_DIR="/root/vpn"
VLESS_DB="$SCRIPT_DIR/config/xray/vless-users.db"
XRAY_CONFIG="$SCRIPT_DIR/config/xray/vless.json"

# Set timezone to Asia/Jakarta
export TZ='Asia/Jakarta'

# Function untuk menampilkan daftar user Vless
list_vless_users() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Vless Users List ($(date '+%Y-%m-%d %H:%M:%S %Z'))"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Check if database exists
    if [[ ! -f "$VLESS_DB" ]]; then
        echo -e "${RED}Vless user database not found!${NC}"
        return 1
    fi

    # Get Vless port
    port=$(grep '"port":' "$XRAY_CONFIG" | cut -d':' -f2 | tr -d ' ,')

    # Print header
    printf "%-20s %-40s %-20s %-15s\n" "Username" "UUID" "Expiration Date" "Status"
    echo "────────────────────────────────────────────────────────────────────────────────"

    # Process each user
    while read -r line; do
        # Skip empty or comment lines
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Extract username, expiration date, and UUID
        username=$(echo "$line" | awk '{print $2}')
        exp_date=$(echo "$line" | awk '{print $3}')
        uuid=$(echo "$line" | awk '{print $4}')

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
        printf "%-20s %-40s %-20s %-15s\n" "$username" "$uuid" "$exp_date" "$status"

    done < <(grep "^### " "$VLESS_DB")

    # Footer
    echo "────────────────────────────────────────────────────────────────────────────────"

    # Additional system info
    echo -e "\nVless Port: $port"
    echo -e "Current Date & Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo -e "Total Vless Users: $(grep -c "^### " "$VLESS_DB")"

    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
list_vless_users
