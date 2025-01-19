#!/bin/bash
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'

# Path
SCRIPT_DIR="/usr/local/vpn"
VMESS_DB="$SCRIPT_DIR/config/xray/vmess-users.db"
XRAY_CONFIG="$SCRIPT_DIR/config/xray/vmess.json"

# Validate username
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
    # Check if exists in Vmess database
    if grep -q "^### $username" "$VMESS_DB" 2>/dev/null; then
        echo -e "${RED}Username '$username' already exists${NC}"
        return 1
    fi
    return 0
}

# Function untuk membuat UUID
generate_uuid() {
    uuid=$(cat /proc/sys/kernel/random/uuid)
    echo "$uuid"
}

# Function untuk menambah user Vmess
add_vmess_user() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                   Add Vmess User                           ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

    # Input username with validation
    while true; do
        read -p "Username : " username
        validate_username "$username" && break
    done

    # Generate single UUID for all configurations
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

    # Get login limit (default 2)
    read -p "Max Login (default: 2) : " limit
    if [[ -z "$limit" ]] || ! [[ "$limit" =~ ^[0-9]+$ ]]; then
        limit=2
    fi

    # Calculate expiry date
    exp=$(date -d "+${duration} days" +"%Y-%m-%d")

    # Get domain
    domain=$(cat "$SCRIPT_DIR/config/domain.conf" 2>/dev/null || echo 'vpn.example.com')

    # Get Vmess port from config
    port=$(grep '"port":' "$XRAY_CONFIG" | cut -d':' -f2 | tr -d ' ,')

    # Path configurations
    echo -e "${YELLOW}Path Configuration:${NC}"
    echo -e "${GREEN}1. WebSocket (WS):${NC}"
    read -p "  Custom WS Path [default: /vmess]: " custom_ws_path
    custom_ws_path=${custom_ws_path:-/vmess}
    # Ensure path starts with /
    custom_ws_path=$(echo "$custom_ws_path" | sed 's:^/*:/:')
    ws_path="$custom_ws_path"

    echo -e "${GREEN}2. WebSocket TLS:${NC}"
    read -p "  Custom WS TLS Path [default: /vmess]: " custom_ws_tls_path
    custom_ws_tls_path=${custom_ws_tls_path:-/vmess}
    # Ensure path starts with /
    custom_ws_tls_path=$(echo "$custom_ws_tls_path" | sed 's:^/*:/:')
    ws_tls_path="$custom_ws_tls_path"

    echo -e "${GREEN}3. gRPC:${NC}"
    read -p "  Custom gRPC Path [default: vmess-grpc]: " custom_grpc_path
    custom_grpc_path=${custom_grpc_path:-vmess-grpc}
    # Remove leading / if present
    custom_grpc_path=$(echo "$custom_grpc_path" | sed 's:^/*::')
    grpc_path="$custom_grpc_path"

    echo -e "${GREEN}4. HTTP Upgrade:${NC}"
    read -p "  Custom HTTP Upgrade Path [default: /httpupgrade]: " custom_httpupgrade_path
    custom_httpupgrade_path=${custom_httpupgrade_path:-/httpupgrade}
    # Ensure path starts with /
    custom_httpupgrade_path=$(echo "$custom_httpupgrade_path" | sed 's:^/*:/:')
    httpupgrade_path="$custom_httpupgrade_path"

    # Add to database (storing all configurations)
    echo "### $username $exp $uuid $limit $ws_path $ws_tls_path $grpc_path $httpupgrade_path" >>"$VMESS_DB"

    # Show configuration
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                 Vmess Account Created                       ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

    echo -e "\n${YELLOW}Account Information:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e " Username      : $username"
    echo -e " UUID          : $uuid"
    echo -e " Expired Date  : $exp"
    echo -e " Max Login     : $limit Device"
    echo -e "└───────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}Server Information:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e " Domain        : $domain"
    echo -e " Port          : $port"
    echo -e "└───────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}Path Details:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e "  • WebSocket (WS)       : $ws_path"
    echo -e "  • WebSocket TLS        : $ws_tls_path"
    echo -e "  • gRPC                 : $grpc_path"
    echo -e "  • HTTP Upgrade         : $httpupgrade_path"
    echo -e "└───────────────────────────────────────────────┘"

    # Generate V2Ray links for different configurations
    echo -e "\n${YELLOW}Connection Links:${NC}"
    echo -e "${GREEN}1. WebSocket (WS) Configuration:${NC}"
    ws_link="vmess://$(echo -n "{
    \"v\": \"2\",
    \"ps\": \"$username-WS\",
    \"add\": \"$domain\",
    \"port\": \"$port\",
    \"id\": \"$uuid\",
    \"aid\": \"0\",
    \"net\": \"ws\",
    \"type\": \"none\",
    \"host\": \"$domain\",
    \"path\": \"$ws_path\",
    \"tls\": \"none\"
}" | base64 -w 0)"
    echo -e "$ws_link"

    echo -e "\n${GREEN}2. WebSocket TLS Configuration:${NC}"
    ws_tls_link="vmess://$(echo -n "{
    \"v\": \"2\",
    \"ps\": \"$username-WS-TLS\",
    \"add\": \"$domain\",
    \"port\": \"$port\",
    \"id\": \"$uuid\",
    \"aid\": \"0\",
    \"net\": \"ws\",
    \"type\": \"none\",
    \"host\": \"$domain\",
    \"path\": \"$ws_tls_path\",
    \"tls\": \"tls\"
}" | base64 -w 0)"
    echo -e "$ws_tls_link"

    echo -e "\n${GREEN}3. gRPC Configuration:${NC}"
    grpc_link="vmess://$(echo -n "{
    \"v\": \"2\",
    \"ps\": \"$username-GRPC\",
    \"add\": \"$domain\",
    \"port\": \"$port\",
    \"id\": \"$uuid\",
    \"aid\": \"0\",
    \"net\": \"grpc\",
    \"type\": \"multi\",
    \"host\": \"$domain\",
    \"path\": \"$grpc_path\",
    \"tls\": \"tls\"
}" | base64 -w 0)"
    echo -e "$grpc_link"

    echo -e "\n${GREEN}4. HTTP Upgrade Configuration:${NC}"
    httpupgrade_link="vmess://$(echo -n "{
    \"v\": \"2\",
    \"ps\": \"$username-HTTP-UPGRADE\",
    \"add\": \"$domain\",
    \"port\": \"$port\",
    \"id\": \"$uuid\",
    \"aid\": \"0\",
    \"net\": \"httpupgrade\",
    \"type\": \"none\",
    \"host\": \"$domain\",
    \"path\": \"$httpupgrade_path\",
    \"tls\": \"tls\"
}" | base64 -w 0)"
    echo -e "$httpupgrade_link"

    echo -e "\n───────────────────────────────────────────────────────────"
    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
add_vmess_user
