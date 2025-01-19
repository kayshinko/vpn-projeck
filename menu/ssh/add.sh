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
    # Check if exists
    if grep -q "^### $username" "$SSH_DB" 2>/dev/null; then
        echo -e "${RED}Username '$username' already exists${NC}"
        return 1
    fi
    # Check if system user exists
    if id "$username" &>/dev/null; then
        echo -e "${RED}System user '$username' already exists${NC}"
        return 1
    fi
    return 0
}

# Validate password
validate_password() {
    local password=$1
    if [ ${#password} -lt 6 ]; then
        echo -e "${RED}Password must be at least 6 characters${NC}"
        return 1
    fi
    return 0
}

# Create user
create_user() {
    local username=$1
    local password=$2
    local exp_date=$3
    local limit=$4

    # Create system user
    useradd -e "$exp_date" -s /bin/false -M "$username"
    echo -e "$password\n$password" | passwd "$username" &>/dev/null

    # Set login limit
    echo "$username - maxlogins $limit" >>/etc/security/limits.conf

    # Add to database
    echo "### $username $exp_date $(date +%Y-%m-%d)" >>"$SSH_DB"
    chmod 600 "$SSH_DB"
}

# Create OpenVPN config
create_ovpn_config() {
    local username=$1
    local domain=$(cat $CONFIG_DIR/domain.conf 2>/dev/null || echo 'vpn.example.com')

    mkdir -p "$OVPN_DIR"
    cat >"$OVPN_DIR/$username.ovpn" <<EOF
client
dev tun
proto udp
remote $domain 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
key-direction 1
verb 3
auth-user-pass
<ca>
$(cat /etc/openvpn/ca.crt 2>/dev/null)
</ca>
EOF
    chmod 600 "$OVPN_DIR/$username.ovpn"
}

# Show account info
show_account_info() {
    local username=$1
    local password=$2
    local exp_date=$3
    local limit=$4
    local domain=$(cat $CONFIG_DIR/domain.conf 2>/dev/null || echo 'Not Set')
    local ip=$(curl -s ipv4.icanhazip.com)

    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           SSH Account Created                  ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    echo -e "\n${YELLOW}Account Information:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e " Username      : $username"
    echo -e " Password      : $password"
    echo -e " Expired Date  : $exp_date"
    echo -e " Max Login     : $limit Device"
    echo -e "└───────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}Server Information:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e " IP Address    : $ip"
    echo -e " Domain        : $domain"
    echo -e " OpenSSH       : 22"
    echo -e " Dropbear      : 109, 143"
    echo -e " SSL/TLS       : 443"
    echo -e " HTTP          : 80"
    echo -e " OpenVPN       : 1194"
    echo -e "└───────────────────────────────────────────────┘"

    echo -e "\n${YELLOW}Payload Information:${NC}"
    echo -e "┌───────────────────────────────────────────────┐"
    echo -e "${GREEN}[GET] Payload:${NC}"
    echo -e "GET / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]"
    echo -e ""
    echo -e "${GREEN}[WebSocket] Payload:${NC}"
    echo -e "GET wss://$domain/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]"
    echo -e ""
    echo -e "${GREEN}[SSL/TLS] Payload:${NC}"
    echo -e "GET wss://$domain/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf]Connection: Keep-Alive[crlf][crlf]"
    echo -e ""
    echo -e "${GREEN}[PATCH] Payload:${NC}"
    echo -e "PATCH / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf]Connection: Keep-Alive[crlf][crlf]"
    echo -e "└───────────────────────────────────────────────┘"

    if [ -f "$OVPN_DIR/$username.ovpn" ]; then
        echo -e "\n${YELLOW}OpenVPN Configuration:${NC}"
        echo -e "┌───────────────────────────────────────────────┐"
        echo -e " Config File   : $OVPN_DIR/$username.ovpn"
        echo -e "└───────────────────────────────────────────────┘"
    fi
}

# Main function
main() {
    # Header
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Add SSH User                      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"

    # Get username
    while true; do
        read -p "Username : " username
        validate_username "$username" && break
    done

    # Get password
    while true; do
        read -p "Password : " password
        validate_password "$password" && break
    done

    # Get duration
    while true; do
        read -p "Duration (days) : " duration
        if [[ "$duration" =~ ^[0-9]+$ ]] && [ "$duration" -gt 0 ]; then
            break
        else
            echo -e "${RED}Please enter a valid number of days${NC}"
        fi
    done

    # Get login limit (default 4)
    read -p "Max Login (default: 4) : " limit
    if [[ -z "$limit" ]] || ! [[ "$limit" =~ ^[0-9]+$ ]]; then
        limit=4
    fi

    # Calculate expiry date
    exp_date=$(date -d "+${duration} days" +"%Y-%m-%d")

    # Create user
    create_user "$username" "$password" "$exp_date" "$limit"

    # Create OpenVPN config
    create_ovpn_config "$username"

    # Show account info
    show_account_info "$username" "$password" "$exp_date" "$limit"

    read -n 1 -s -r -p "Press any key to continue"
    clear
}

# Run main function
main
