#!/bin/bash
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
# Path
SCRIPT_DIR="/root/vpn"
TROJAN_DB="$SCRIPT_DIR/config/xray/trojan-users.db"
XRAY_CONFIG="$SCRIPT_DIR/config/xray/trojan.json"

# Function untuk generate password
generate_password() {
    # Generate a strong random password
    password=$(openssl rand -base64 12)
    echo "$password"
}

# Function untuk menambah user Trojan
add_trojan_user() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Add Trojan User"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Input username
    read -p "Username : " username

    # Check if username exists
    if grep -q "^### $username" "$TROJAN_DB" 2>/dev/null; then
        echo -e "${RED}User $username already exists${NC}"
        return 1
    fi

    # Generate or input password
    while true; do
        read -p "Use auto-generated password? [Y/n]: " use_auto
        use_auto=${use_auto:-Y}

        if [[ "$use_auto" =~ ^[Yy]$ ]]; then
            password=$(generate_password)
            break
        elif [[ "$use_auto" =~ ^[Nn]$ ]]; then
            read -p "Enter password: " password
            # Optional: Add password strength check
            if [[ ${#password} -lt 8 ]]; then
                echo -e "${RED}Password must be at least 8 characters long!${NC}"
                continue
            fi
            break
        else
            echo -e "${RED}Invalid input. Please enter Y or N.${NC}"
        fi
    done

    # Input duration (days)
    read -p "Duration (days) : " duration

    # Calculate expiry date
    exp=$(date -d "+${duration} days" +"%Y-%m-%d")

    # Get domain
    domain=$(cat "$SCRIPT_DIR/config/domain.conf" 2>/dev/null || echo 'vpn.example.com')

    # Get Trojan port from config
    port=$(grep '"port":' "$XRAY_CONFIG" | cut -d':' -f2 | tr -d ' ,')

    # Path configuration
    echo -e "Path Configuration:"

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
    echo "### $username $exp $password $ws_path $ws_tls_path $grpc_path" >>"$TROJAN_DB"

    # Show configuration
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Trojan Account Created"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
    echo -e "Username : $username"
    echo -e "Password : $password"
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
    echo -e "Trojan Links:"

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

    echo -e "───────────────────────────────────────────────────────────"
    read -n 1 -s -r -p "Press any key to continue"
}

# Run function
add_trojan_user
