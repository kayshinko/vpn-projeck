#!/bin/bash
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
# Path
SCRIPT_DIR="/root/vpn"
VLESS_DB="$SCRIPT_DIR/config/xray/vless-users.db"

# Function untuk menghapus user Vless
del_vless_user() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Delete Vless User"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Check if database is empty
    if [[ ! -s "$VLESS_DB" ]]; then
        echo -e "${RED}No Vless users found in the database${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    # List users with numbers
    echo -e "Existing Vless Users:"
    echo -e "───────────────────────────────────────────────────────────"
    # Use a counter to number the users
    counter=0
    while read -r line; do
        # Skip empty or comment lines
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Extract username and expiration date
        username=$(echo "$line" | awk '{print $2}')
        exp_date=$(echo "$line" | awk '{print $3}')

        # Increment counter
        ((counter++))

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

        # Store user details in an array
        users_array[$counter]="$line"

        # Print numbered list
        printf "[%2d] %-15s | Expires: %-15s | Status: %s\n" "$counter" "$username" "$exp_date" "$status"

    done < <(grep "^### " "$VLESS_DB")

    # Check if any users were found
    if [[ $counter -eq 0 ]]; then
        echo -e "${RED}No Vless users found${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    echo -e "───────────────────────────────────────────────────────────"
    # Prompt for user selection
    read -p "Enter the number of the user to delete [1-$counter]: " user_number

    # Validate user selection
    if [[ ! "$user_number" =~ ^[0-9]+$ ]] || [[ "$user_number" -lt 1 ]] || [[ "$user_number" -gt $counter ]]; then
        echo -e "${RED}Invalid selection${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    # Get selected user details
    selected_user="${users_array[$user_number]}"
    username=$(echo "$selected_user" | awk '{print $2}')
    exp_date=$(echo "$selected_user" | awk '{print $3}')

    # Confirm deletion
    read -p "Are you sure want to delete user $username? [y/N] : " confirm
    if [[ "$confirm" != [Yy]* ]]; then
        echo -e "${RED}Deletion cancelled${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    # Remove from database
    sed -i "/^### $username $exp_date /d" "$VLESS_DB"

    # Show confirmation
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Vless User Deleted"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
    echo -e "Username : $username"
    echo -e "Expiry Date : $exp_date"
    echo -e "Status : ${GREEN}Successfully Deleted${NC}"

    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
del_vless_user
