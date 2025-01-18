#!/bin/bash
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
# Path
SCRIPT_DIR="/root/vpn"
VLESS_DB="$SCRIPT_DIR/config/xray/vless-users.db"
XRAY_CONFIG="$SCRIPT_DIR/config/xray/vless.json"

# Function untuk membuat UUID
generate_uuid() {
    uuid=$(cat /proc/sys/kernel/random/uuid)
    echo "$uuid"
}

# Function untuk menambah user Vless
add_vless_user() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Add Vless User"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Input username
    read -p "Username : " username

    # Check if username exists
    if grep -q "^### $username" "$VLESS_DB" 2>/dev/null; then
        echo -e "${RED}User $username already exists${NC}"
        return 1
    fi

    # Generate UUID
    uuid=$(generate_uuid)

    # Input duration (days)
    read -p "Duration (days) : " duration

    # Calculate expiry date
    exp=$(date -d "+${duration} days" +"%Y-%m-%d")

    # Get domain
    domain=$(cat "$SCRIPT_DIR/config/domain.conf" 2>/dev/null || echo 'vpn.example.com')

    # Get Vless port from config
    port=$(grep '"port":' "$XRAY_CONFIG" | cut -d':' -f2 | tr -d ' ,')

    # Path configuration
    echo -e "Path Configuration:"
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
    echo "### $username $exp $uuid $ws_path $ws_tls_path $grpc_path" >>"$VLESS_DB"

    # Show configuration
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Vless Account Created"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
    echo -e "Username : $username"
    echo -e "UUID : $uuid"
    echo -e "Expired Date : $exp"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "Domain : $domain"
    echo -e "Port : $port"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "Path Details:"
    echo -e "  • WebSocket (WS)    : $ws_path"
    echo -e "  • WebSocket TLS     : $ws_tls_path"
    echo -e "  • gRPC              : $grpc_path"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "Vless Link (WS):"
    # Generate Vless links
    ws_link="vless://$uuid@$domain:$port?type=ws&security=none&path=$ws_path#$username-WS"
    echo -e "$ws_link"

    echo -e "\nVless Link (WS TLS):"
    ws_tls_link="vless://$uuid@$domain:$port?type=ws&security=tls&path=$ws_tls_path#$username-WS-TLS"
    echo -e "$ws_tls_link"

    echo -e "\nVless Link (gRPC):"
    grpc_link="vless://$uuid@$domain:$port?type=grpc&security=tls&serviceName=$grpc_path#$username-GRPC"
    echo -e "$grpc_link"

    echo -e "───────────────────────────────────────────────────────────"
    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
add_vless_user
