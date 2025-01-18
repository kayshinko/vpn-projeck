#!/bin/bash
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
# Path
SCRIPT_DIR="/root/vpn"
SSH_DB="$SCRIPT_DIR/config/ssh-users.db"
OVPN_DIR="/root/vpn/config/openvpn"

# Function untuk menambah user
add_ssh_user() {
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Add SSH User"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
    # Input username
    read -p "Username : " username
    # Check if username exists
    if grep -q "^### $username" "$SSH_DB" 2>/dev/null; then
        echo -e "${RED}User $username already exists${NC}"
        return 1
    fi
    # Input password
    read -p "Password : " password
    # Input duration (days)
    read -p "Duration (days) : " duration
    # Calculate expiry date
    exp=$(date -d "+${duration} days" +"%Y-%m-%d")
    # Create system user
    useradd -e "$exp" -s /bin/false -M "$username"
    echo -e "$password\n$password" | passwd "$username" &>/dev/null
    # Add to database
    echo "### $username $exp" >>"$SSH_DB"

    # Create OpenVPN configuration
    mkdir -p "$OVPN_DIR"
    # Generate OpenVPN client configuration
    cat >"$OVPN_DIR/$username.ovpn" <<EOF
client
dev tun
proto udp
remote $(cat $SCRIPT_DIR/config/domain.conf 2>/dev/null || echo 'vpn.example.com') 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
auth-user-pass
<ca>
$(cat /etc/openvpn/ca.crt 2>/dev/null)
</ca>
<cert>
$(cat /etc/openvpn/issued/$username.crt 2>/dev/null)
</cert>
<key>
$(cat /etc/openvpn/private/$username.key 2>/dev/null)
</key>
EOF

    # Show configuration
    clear
    echo -e "\033[5;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " SSH Account Created"
    echo -e "\033[5;34m╘═══════════════════════════════════════════════════════════╛\033[0m"
    echo -e "Username : $username"
    echo -e "Password : $password"
    echo -e "Expired Date : $exp"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "IP : $(curl -s ipv4.icanhazip.com)"
    echo -e "Host : $(cat $SCRIPT_DIR/config/domain.conf 2>/dev/null || echo 'Not Set')"
    echo -e "OpenSSH : 22"
    echo -e "Dropbear : 109, 143"
    echo -e "SSL/TLS : 443"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "SSH UDP : 1-65535"
    echo -e "OpenVPN : 1194"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "Payload Websocket & Custom"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "${GREEN}[GET] Payload:${NC}"
    echo -e "GET / HTTP/1.1[crlf]Host: $(cat $SCRIPT_DIR/config/domain.conf 2>/dev/null || echo 'cdn.example.com')[crlf]Upgrade: websocket[crlf][crlf]"
    echo -e ""
    echo -e "${GREEN}[WebSocket] Payload:${NC}"
    echo -e "GET wss://$(cat $SCRIPT_DIR/config/domain.conf 2>/dev/null || echo 'bug.com')/ HTTP/1.1[crlf]Host: $(cat $SCRIPT_DIR/config/domain.conf 2>/dev/null || echo 'bug.com')[crlf]Upgrade: websocket[crlf][crlf]"
    echo -e ""
    echo -e "${GREEN}[SSL/TLS] Payload:${NC}"
    echo -e "GET wss://$(cat $SCRIPT_DIR/config/domain.conf 2>/dev/null || echo 'bug.com')/ HTTP/1.1[crlf]Host: $(cat $SCRIPT_DIR/config/domain.conf 2>/dev/null || echo 'bug.com')[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf]Connection: Keep-Alive[crlf][crlf]"
    echo -e ""
    echo -e "${GREEN}[PATCH] Payload:${NC}"
    echo -e "PATCH / HTTP/1.1[crlf]Host: $(cat $SCRIPT_DIR/config/domain.conf 2>/dev/null || echo 'bug.com')[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf]Connection: Keep-Alive[crlf][crlf]"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "${GREEN}OpenVPN Configuration:${NC}"
    echo -e "Config File : $OVPN_DIR/$username.ovpn"
    echo -e "───────────────────────────────────────────────────────────"
    read -n 1 -s -r -p "Press any key to continue"
}
# Run function
add_ssh_user
