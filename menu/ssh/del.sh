#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
VPN_DIR="/usr/local/vpn"
CONFIG_DIR="$VPN_DIR/config"
SSH_DB="$CONFIG_DIR/ssh-users.db"
OVPN_DIR="$CONFIG_DIR/openvpn"

# Function to check if database exists and is not empty
check_database() {
    if [ ! -f "$SSH_DB" ] || [ ! -s "$SSH_DB" ]; then
        echo -e "${RED}No SSH users found in the database${NC}"
        return 1
    fi
    return 0
}

# Function to get user status
get_user_status() {
    local exp_date=$1
    local days_remaining=$((($(date -d "$exp_date" +%s) - $(date +%s)) / 86400))

    if [[ "$days_remaining" -lt 0 ]]; then
        echo "${RED}Expired${NC}"
    elif [[ "$days_remaining" -le 3 ]]; then
        echo "${YELLOW}Expiring Soon (${days_remaining}d)${NC}"
    else
        echo "${GREEN}Active (${days_remaining}d)${NC}"
    fi
}

# Function to list users
list_users() {
    local counter=0
    declare -A user_details

    echo -e "\n${YELLOW}Existing SSH Users:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    printf "%-4s %-15s %-15s %-25s\n" "No." "Username" "Expiry Date" "Status"
    echo -e "├─────────────────────────────────────────────────────────────┤"

    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue

        username=$(echo "$line" | awk '{print $2}')
        exp_date=$(echo "$line" | awk '{print $3}')
        ((counter++))

        # Store user details
        user_details["$counter"]="$line"

        # Get status
        status=$(get_user_status "$exp_date")

        printf "%-4s %-15s %-15s %-25s\n" "[$counter]" "$username" "$exp_date" "$status"
    done < <(grep "^### " "$SSH_DB")

    echo -e "└─────────────────────────────────────────────────────────────┘"

    if [[ $counter -eq 0 ]]; then
        echo -e "${RED}No SSH users found${NC}"
        return 1
    fi

    echo -e "\nTotal users: $counter"
    return 0
}

# Function to delete user
delete_user() {
    local username=$1
    local exp_date=$2

    # Delete system user
    userdel -r "$username" 2>/dev/null

    # Remove from database
    sed -i "/^### $username /d" "$SSH_DB"

    # Remove OpenVPN config if exists
    rm -f "$OVPN_DIR/$username.ovpn" 2>/dev/null

    # Remove any associated files
    rm -f "/etc/openvpn/client/$username" 2>/dev/null
    rm -f "/var/log/openvpn/$username.log" 2>/dev/null

    # Kill user sessions
    pkill -u "$username" 2>/dev/null

    return 0
}

# Function to show deletion result
show_deletion_result() {
    local username=$1
    local exp_date=$2

    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║             SSH User Deleted                   ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    echo -e "\n${YELLOW}Deletion Details:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e " Username     : $username"
    echo -e " Expiry Date  : $exp_date"
    echo -e " Status       : ${GREEN}Successfully Deleted${NC}"
    echo -e "└───────────────────────────────────────────────┘"
}

# Main function
main() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║            Delete SSH User                     ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    # Check database
    check_database || {
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    }

    # List users
    list_users || {
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    }

    # Get user selection
    echo -e "\n${YELLOW}User Deletion:${NC}"
    read -p "Enter the number of user to delete: " user_number

    # Validate selection
    if ! grep -q "^### " "$SSH_DB" 2>/dev/null; then
        echo -e "${RED}No users found in database${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    # Get selected user
    selected_line=$(sed -n "${user_number}p" <(grep "^### " "$SSH_DB"))

    if [ -z "$selected_line" ]; then
        echo -e "${RED}Invalid selection${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    username=$(echo "$selected_line" | awk '{print $2}')
    exp_date=$(echo "$selected_line" | awk '{print $3}')

    # Confirm deletion
    echo -e "\nSelected user: ${YELLOW}$username${NC} (Expires: $exp_date)"
    read -p "Are you sure you want to delete this user? [y/N]: " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        delete_user "$username" "$exp_date" &&
            show_deletion_result "$username" "$exp_date"
    else
        echo -e "${YELLOW}Deletion cancelled${NC}"
    fi

    read -n 1 -s -r -p "Press any key to continue"
}

# Run main function
main
