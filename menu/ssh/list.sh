#!/bin/bash
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
# Path
SCRIPT_DIR="/root/vpn"
SSH_DB="$SCRIPT_DIR/config/ssh-users.db"

# Set timezone to Asia/Jakarta
export TZ='Asia/Jakarta'

# Function untuk menampilkan daftar user
list_ssh_users() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " SSH Users List ($(date '+%Y-%m-%d %H:%M:%S %Z'))"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Check if database exists
    if [[ ! -f "$SSH_DB" ]]; then
        echo -e "${RED}SSH user database not found!${NC}"
        return 1
    fi

    # Print header
    printf "%-20s %-20s %-15s %-15s\n" "Username" "Expiration Date" "Days Remaining" "Status"
    echo "────────────────────────────────────────────────────────────────────────────────"

    # Process each user
    while read -r line; do
        # Skip empty or comment lines
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Extract username and expiration date
        username=$(echo "$line" | awk '{print $2}')
        exp_date=$(echo "$line" | awk '{print $3}')

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
        printf "%-20s %-20s %-15s %-15s\n" "$username" "$exp_date" "$days_remaining" "$status"

    done < <(grep "^### " "$SSH_DB")

    # Footer
    echo "────────────────────────────────────────────────────────────────────────────────"

    # Additional system info
    echo -e "\nCurrent Date & Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo -e "Active SSH Connections: $(who | grep -c pts)"
    echo -e "SSH Service Status: $(systemctl is-active ssh)"

    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
list_ssh_users
