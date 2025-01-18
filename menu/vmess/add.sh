#!/bin/bash
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
# Path
SCRIPT_DIR="/root/vpn"
VMESS_DB="$SCRIPT_DIR/config/xray/vmess-users.db"
XRAY_CONFIG="$SCRIPT_DIR/config/xray/vmess.json"

# Function untuk membuat UUID
generate_uuid() {
    uuid=$(cat /proc/sys/kernel/random/uuid)
    echo "$uuid"
}

# Function untuk menambah user Vmess
add_vmess_user() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Add Vmess User"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Input username
    read -p "Username : " username

    # Check if username exists
    if grep -q "^### $username" "$VMESS_DB" 2>/dev/null; then
        echo -e "${RED}User $username already exists${NC}"
        return 1
    fi

    # Generate single UUID for all configurations
    uuid=$(generate_uuid)

    # Input duration (days)
    read -p "Duration (days) : " duration

    # Calculate expiry date
    exp=$(date -d "+${duration} days" +"%Y-%m-%d")

    # Get domain
    domain=$(cat "$SCRIPT_DIR/config/domain.conf" 2>/dev/null || echo 'vpn.example.com')

    # Get Vmess port from config
    port=$(grep '"port":' "$XRAY_CONFIG" | cut -d':' -f2 | tr -d ' ,')

    # Add to database (storing all configurations)
    echo "### $username $exp $uuid $ws_path $ws_tls_path $grpc_path $httpupgrade_path" >>"$VMESS_DB"

    # Show configuration
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Vmess Account Created"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
    echo -e "Username : $username"
    echo -e "UUID : $uuid"
    echo -e "Expired Date : $exp"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "Domain : $domain"
    echo -e "Port : $port"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "Path Configuration:"
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

    echo -e "───────────────────────────────────────────────────────────"
    echo -e "${BLUE}Path Details:${NC}"
    echo -e "  • WebSocket (WS)       : $ws_path"
    echo -e "  • WebSocket TLS        : $ws_tls_path"
    echo -e "  • gRPC                 : $grpc_path"
    echo -e "  • HTTP Upgrade         : $httpupgrade_path"
    echo -e "───────────────────────────────────────────────────────────"

    # Generate V2Ray links for different configurations
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

    echo -e "───────────────────────────────────────────────────────────"
    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
add_vmess_user
