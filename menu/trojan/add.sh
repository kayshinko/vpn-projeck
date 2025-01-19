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

# Function to validate username
validate_username() {
    local username=$1
    # Check length
    if [ ${#username} -lt 3 ] || [ ${#username} -gt 32 ]; then
        echo -e "${RED}Username must be between 3 and 32 characters${NC}"
        return 1
    fi
    # Check characters
    if ! [[ $username =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Username can only contain letters, numbers, hyphen and underscore${NC}"
        return 1
    fi
    # Check if exists in Trojan database
    if grep -q "^### $username" "$TROJAN_DB" 2>/dev/null; then
        echo -e "${RED}Username '$username' already exists${NC}"
        return 1
    fi
    return 0
}

# Function to generate password
generate_password() {
    # Generate a strong random password
    password=$(openssl rand -base64 12)
    echo "$password"
}

# Function to add Trojan user
add_trojan_user() {
    clear
    echo -e "${BLUE}╒═══════════════════════════════════════════════════════════╕${NC}"
    echo -e "${BLUE}║                    Add Trojan User                         ║${NC}"
    echo -e "${BLUE}╘═══════════════════════════════════════════════════════════╝${NC}"

    # Input and validate username
    while true; do
        read -p "Username : " username
        validate_username "$username" && break
    done

    # Generate or input password
    while true; do
        read -p "Use auto-generated password? [Y/n]: " use_auto
        use_auto=${use_auto:-Y}

        if [[ "$use_auto" =~ ^[Yy]$ ]]; then
            password=$(generate_password)
            break
        elif [[ "$use_auto" =~ ^[Nn]$ ]]; then
            while true; do
                read -p "Enter password: " password
                # Optional: Add password strength check
                if [[ ${#password} -lt 8 ]]; then
                    echo -e "${RED}Password must be at least 8 characters long!${NC}"
                else
                    break
                fi
            done
            break
        else
            echo -e "${RED}Invalid input. Please enter Y or N.${NC}"
        fi
    done

    # Input duration (days)
    while true; do
        read -p "Duration (days) : " duration
        if [[ "$duration" =~ ^[0-9]+$ ]] && [ "$duration" -gt 0 ]; then
            break
        else
            echo -e "${RED}Please enter a valid number of days${NC}"
        fi
    done

    # Input max login (default 2)
    read -p "Max Login (default: 2) : " max_login
    if [[ -z "$max_login" ]] || ! [[ "$max_login" =~ ^[0-9]+$ ]]; then
        max_login=2
    fi

    # Calculate expiry date
    exp=$(date -d "+${duration} days" +"%Y-%m-%d")

    # Get domain
    domain=$(cat "$SCRIPT_DIR/config/domain.conf" 2>/dev/null || echo 'vpn.example.com')

    # Get Trojan port from config
    port=$(grep '"port":' "$XRAY_CONFIG" | cut -d':' -f2 | tr -d ' ,')

    # Path configuration
    echo -e "\n${YELLOW}Path Configuration:${NC}"
    echo -e "${GREEN}1. WebSocket (WS):${NC}"
    read -p "  Custom WS Path [default: /trojan]: " custom_ws_path
    custom_ws_path=${custom_ws_path:-/trojan}
    # Ensure path starts with /
    custom_ws_path=$(echo "$custom_ws_path" | sed 's:^/*:/:')
    ws_path="$custom_ws_path"

    echo -e "${GREEN}2. WebSocket TLS:${NC}"
    read -p "  Custom WS TLS Path [default: /trojantls]: " custom_ws_tls_path
    custom_ws_tls_path=${custom_ws_tls_path:-/trojantls}
    # Ensure path starts with /
    custom_ws_tls_path=$(echo "$custom_ws_tls_path" | sed 's:^/*:/:')
    ws_tls_path="$custom_ws_tls_path"

    echo -e "${GREEN}3. gRPC:${NC}"
    read -p "  Custom gRPC Path [default: trojan-grpc]: " custom_grpc_path
    custom_grpc_path=${custom_grpc_path:-trojan-grpc}
    # Remove leading / if present
    custom_grpc_path=$(echo "$custom_grpc_path" | sed 's:^/*::')
    grpc_path="$custom_grpc_path"

    # Add to database (storing all configurations)
    echo "### $username $exp $password $max_login $ws_path $ws_tls_path $grpc_path" >>"$TROJAN_DB"

    # Show configuration
    clear
    echo -e "${BLUE}╒═══════════════════════════════════════════════════════════╕${NC}"
    echo -e "${BLUE}║                Trojan Account Created                       ║${NC}"
    echo -e "${BLUE}╘═══════════════════════════════════════════════════════════╝${NC}"

    echo -e "\n${YELLOW}Account Information:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e " Username      : $username"
    echo -e " Password      : $password"
    echo -e " Expired Date  : $exp"
    echo -e " Max Login     : $max_login Device"
    echo -e "└───────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}Server Information:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e " Domain        : $domain"
    echo -e " Port          : $port"
    echo -e "└───────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}Path Details:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e "  • WebSocket (WS)    : $ws_path"
    echo -e "  • WebSocket TLS     : $ws_tls_path"
    echo -e "  • gRPC              : $grpc_path"
    echo -e "└───────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}Trojan Links:${NC}"
    # Generate Trojan links
    echo -e "${GREEN}1. Trojan WebSocket (WS):${NC}"
    ws_link="trojan://$password@$domain:$port?type=ws&path=$ws_path&security=none&host=$domain#$username-WS"
    echo -e "$ws_link"

    echo -e "\n${GREEN}2. Trojan WebSocket TLS:${NC}"
    ws_tls_link="trojan://$password@$domain:$port?type=ws&path=$ws_tls_path&security=tls&host=$domain#$username-WS-TLS"
    echo -e "$ws_tls_link"

    echo -e "\n${GREEN}3. Trojan gRPC:${NC}"
    grpc_link="trojan://$password@$domain:$port?type=grpc&serviceName=$grpc_path&security=tls&host=$domain#$username-GRPC"
    echo -e "$grpc_link"

    echo -e "\n───────────────────────────────────────────────────────────"
    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
add_trojan_user
