#!/bin/bash
# Colors
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'

# Paths
SCRIPT_DIR="/usr/local/vpn"
VLESS_DB="$SCRIPT_DIR/config/xray/vless-users.db"

# Function to extend Vless user
extend_vless_user() {
    clear
    echo -e "${BLUE}╒═══════════════════════════════════════════════════════════╕${NC}"
    echo -e "${BLUE}║                  Extend Vless User                         ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

    # Check if database is empty
    if [[ ! -s "$VLESS_DB" ]]; then
        echo -e "${RED}No Vless users found in the database${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    # List users with details
    echo -e "${YELLOW}Existing Vless Users:${NC}"
    echo -e "───────────────────────────────────────────────────────────"

    # Use a counter to number the users and store details
    declare -a users_array
    counter=0

    # Read and process user entries
    while read -r line; do
        # Skip empty or comment lines
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Extract user details
        username=$(echo "$line" | awk '{print $2}')
        exp_date=$(echo "$line" | awk '{print $3}')
        # Default to 2 if no limit is stored (compatibility with previous versions)
        max_login=$(echo "$line" | awk '{print $4 ? $4 : 2}')

        # Increment counter
        ((counter++))

        # Calculate days remaining
        days_remaining=$((($(date -d "$exp_date" +%s) - $(date +%s)) / 86400))

        # Determine status
        if [[ "$days_remaining" -lt 0 ]]; then
            status="${RED}Expired${NC}"
        elif [[ "$days_remaining" -le 3 ]]; then
            status="${YELLOW}Expiring Soon${NC}"
        else
            status="${GREEN}Active${NC}"
        fi

        # Store user details in an array
        users_array[$counter]="$line"

        # Print numbered list
        printf "[%2d] %-15s | Expires: %-15s | Max Login: %-5s | Status: %s\n" \
            "$counter" "$username" "$exp_date" "$max_login" "$status"
    done < <(grep "^### " "$VLESS_DB")

    # Check if any users were found
    if [[ $counter -eq 0 ]]; then
        echo -e "${RED}No Vless users found${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    echo -e "───────────────────────────────────────────────────────────"

    # Prompt for user selection
    read -p "Enter the number of the user to extend [1-$counter]: " user_number

    # Validate user selection
    if [[ ! "$user_number" =~ ^[0-9]+$ ]] || [[ "$user_number" -lt 1 ]] || [[ "$user_number" -gt $counter ]]; then
        echo -e "${RED}Invalid selection${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    # Get selected user details
    selected_user="${users_array[$user_number]}"
    username=$(echo "$selected_user" | awk '{print $2}')
    current_exp=$(echo "$selected_user" | awk '{print $3}')
    # Default to 2 if no limit is stored
    current_max_login=$(echo "$selected_user" | awk '{print $4 ? $4 : 2}')

    # Input extension duration
    while true; do
        read -p "Extend duration (days) : " duration
        if [[ "$duration" =~ ^[0-9]+$ ]] && [ "$duration" -gt 0 ]; then
            break
        else
            echo -e "${RED}Please enter a valid number of days${NC}"
        fi
    done

    # Calculate new expiry date
    new_exp=$(date -d "$current_exp +${duration} days" +"%Y-%m-%d")

    # Prompt to change max login
    read -p "Current max login is $current_max_login. Do you want to change it? [y/N] : " change_login

    if [[ "$change_login" =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter new max login limit : " new_max_login
            if [[ "$new_max_login" =~ ^[0-9]+$ ]] && [ "$new_max_login" -gt 0 ]; then
                break
            else
                echo -e "${RED}Please enter a valid number${NC}"
            fi
        done
    else
        new_max_login=$current_max_login
    fi

    # Update database (for entries with limit)
    sed -i "s/^### $username $current_exp .*/### $username $new_exp $new_max_login/" "$VLESS_DB"

    # Show configuration
    clear
    echo -e "${BLUE}╒═══════════════════════════════════════════════════════════╕${NC}"
    echo -e "${BLUE}║               Vless Account Extended                        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

    echo -e "\n${YELLOW}Extension Details:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e " Username      : $username"
    echo -e " Old Expiry    : $current_exp"
    echo -e " New Expiry    : $new_exp"
    echo -e " Max Login     : $new_max_login"
    echo -e " Status        : ${GREEN}Successfully Extended${NC}"
    echo -e "└───────────────────────────────────────────────┘"

    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
extend_vless_user
