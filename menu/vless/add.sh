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
XRAY_CONFIG="$SCRIPT_DIR/config/xray/vless.json"

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
    # Check if exists in Vless database
    if grep -q "^### $username" "$VLESS_DB" 2>/dev/null; then
        echo -e "${RED}Username '$username' already exists${NC}"
        return 1
    fi
    return 0
}

# Function to generate UUID
generate_uuid() {
    uuid=$(cat /proc/sys/kernel/random/uuid)
    echo "$uuid"
}

# Function to add Vless user
add_vless_user() {
    clear
    echo -e "${BLUE}╒═══════════════════════════════════════════════════════════╕${NC}"
    echo -e "${BLUE}║                    Add Vless User                          ║${NC}"
    echo -e "${BLUE}╘═══════════════════════════════════════════════════════════╝${NC}"

    # Input and validate username
    while true; do
        read -p "Username : " username
        validate_username "$username" && break
    done

    # Generate UUID
    uuid=$(generate_uuid)

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

    # Get Vless port from config
    port=$(grep '"port":' "$XRAY_CONFIG" | cut -d':' -f2 | tr -d ' ,')

    # Path configuration
    echo -e "\n${YELLOW}Path Configuration:${NC}"
    echo -e "${GREEN}1. WebSocket (WS):${NC}"
    read -p "  Custom WS Path [default: /vless]: " custom_ws_path
    custom_ws_path=${custom_ws_path:-/vless}
    # Ensure path starts with /
    custom_ws_path=$(echo "$custom_ws_path" | sed 's:^/*:/:')
    ws_path="$custom_ws_path"

    echo -e "${GREEN}2. WebSocket TLS:${NC}"
    read -p "  Custom WS TLS Path [default: /vless]: " custom_ws_tls_path
    custom_ws_tls_path=${custom_ws_tls_path:-/vless}
    # Ensure path starts with /
    custom_ws_tls_path=$(echo "$custom_ws_tls_path" | sed 's:^/*:/:')
    ws_tls_path="$custom_ws_tls_path"

    echo -e "${GREEN}3. gRPC:${NC}"
    read -p "  Custom gRPC Path [default: vless-grpc]: " custom_grpc_path
    custom_grpc_path=${custom_grpc_path:-vless-grpc}
    # Remove leading / if present
    custom_grpc_path=$(echo "$custom_grpc_path" | sed 's:^/*::')
    grpc_path="$custom_grpc_path"

    # Add to database (storing all configurations)
    echo "### $username $exp $uuid $max_login $ws_path $ws_tls_path $grpc_path" >>"$VLESS_DB"

    # Show configuration
    clear
    echo -e "${BLUE}╒═══════════════════════════════════════════════════════════╕${NC}"
    echo -e "${BLUE}║                Vless Account Created                        ║${NC}"
    echo -e "${BLUE}╘═══════════════════════════════════════════════════════════╝${NC}"

    echo -e "\n${YELLOW}Account Information:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e " Username      : $username"
    echo -e " UUID          : $uuid"
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
    echo -e " • WebSocket (WS)   : $ws_path"
    echo -e " • WebSocket TLS    : $ws_tls_path"
    echo -e " • gRPC             : $grpc_path"
    echo -e "└───────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}Connection Links:${NC}"
    # Generate Vless links
    echo -e "${GREEN}1. Vless Link (WS):${NC}"
    ws_link="vless://$uuid@$domain:$port?type=ws&security=none&path=$ws_path#$username-WS"
    echo -e "$ws_link"

    echo -e "\n${GREEN}2. Vless Link (WS TLS):${NC}"
    ws_tls_link="vless://$uuid@$domain:$port?type=ws&security=tls&path=$ws_tls_path#$username-WS-TLS"
    echo -e "$ws_tls_link"

    echo -e "\n${GREEN}3. Vless Link (gRPC):${NC}"
    grpc_link="vless://$uuid@$domain:$port?type=grpc&security=tls&serviceName=$grpc_path#$username-GRPC"
    echo -e "$grpc_link"

    echo -e "\n───────────────────────────────────────────────────────────"
    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
add_vless_user
