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

# Function to check database
check_database() {
    if [ ! -f "$SSH_DB" ] || [ ! -s "$SSH_DB" ]; then
        echo -e "${RED}No SSH users found in the database${NC}"
        return 1
    fi
    return 0
}

# Function to get user status and remaining days
get_user_status() {
    local exp_date=$1
    local days_remaining=$((($(date -d "$exp_date" +%s) - $(date +%s)) / 86400))

    if [[ "$days_remaining" -lt 0 ]]; then
        echo "${RED}Expired (${days_remaining}d)${NC}"
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

    echo -e "\n${YELLOW}Current SSH Users:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    printf "%-4s %-15s %-15s %-25s\n" "No." "Username" "Expiry Date" "Status"
    echo -e "├─────────────────────────────────────────────────────────────┤"

    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue

        username=$(echo "$line" | awk '{print $2}')
        exp_date=$(echo "$line" | awk '{print $3}')
        ((counter++))

        user_details["$counter"]="$line"
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

# Function to extend user expiry
extend_user() {
    local username=$1
    local current_exp=$2
    local duration=$3
    local new_exp=$(date -d "$current_exp +${duration} days" +"%Y-%m-%d")

    # Create backup
    cp "$SSH_DB" "${SSH_DB}.bak"

    # Update system user expiration
    chage -E "$new_exp" "$username"

    # Update database
    sed -i "s/^### $username $current_exp$/### $username $new_exp/" "$SSH_DB"

    return 0
}

# Function to validate duration
validate_duration() {
    local duration=$1
    if ! [[ "$duration" =~ ^[0-9]+$ ]] || [ "$duration" -lt 1 ] || [ "$duration" -gt 365 ]; then
        echo -e "${RED}Invalid duration. Please enter a number between 1 and 365${NC}"
        return 1
    fi
    return 0
}

# Function to show extension result
show_extension_result() {
    local username=$1
    local old_exp=$2
    local new_exp=$3
    local added_days=$4

    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║            SSH Account Extended                ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    echo -e "\n${YELLOW}Extension Details:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e " Username      : $username"
    echo -e " Previous Exp. : $old_exp"
    echo -e " Extended By   : $added_days days"
    echo -e " New Expiry    : $new_exp"
    echo -e " Status        : ${GREEN}Successfully Extended${NC}"
    echo -e "└───────────────────────────────────────────────┘"
}

# Main function
main() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║            Extend SSH User                     ║${NC}"
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
    echo -e "\n${YELLOW}User Extension:${NC}"
    read -p "Enter the number of user to extend: " user_number

    # Get selected user
    selected_line=$(sed -n "${user_number}p" <(grep "^### " "$SSH_DB"))

    if [ -z "$selected_line" ]; then
        echo -e "${RED}Invalid selection${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    username=$(echo "$selected_line" | awk '{print $2}')
    current_exp=$(echo "$selected_line" | awk '{print $3}')

    # Get extension duration
    while true; do
        read -p "Enter extension duration (days): " duration
        validate_duration "$duration" && break
    done

    # Confirm extension
    echo -e "\nSelected user: ${YELLOW}$username${NC}"
    echo -e "Current expiry: $current_exp"
    echo -e "Will extend by: $duration days"
    read -p "Continue with extension? [y/N]: " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        if extend_user "$username" "$current_exp" "$duration"; then
            new_exp=$(date -d "$current_exp +${duration} days" +"%Y-%m-%d")
            show_extension_result "$username" "$current_exp" "$new_exp" "$duration"
        else
            echo -e "${RED}Failed to extend user${NC}"
        fi
    else
        echo -e "${YELLOW}Extension cancelled${NC}"
    fi

    read -n 1 -s -r -p "Press any key to continue"
}

# Run main function
main
