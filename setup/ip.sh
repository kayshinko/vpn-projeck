#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
VPN_DIR="/usr/local/vpn"
WHITELIST_FILE="$VPN_DIR/config/ip-whitelist.conf"
CLOUDFLARE_IPS_FILE="$VPN_DIR/config/cloudflare-ips.conf"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Function to get Cloudflare IPs
get_cloudflare_ips() {
    # Create temporary files
    local ipv4_temp="/tmp/cf_ipv4.txt"
    local ipv6_temp="/tmp/cf_ipv6.txt"

    # Download Cloudflare IP ranges
    curl -s https://www.cloudflare.com/ips-v4 >"$ipv4_temp"
    curl -s https://www.cloudflare.com/ips-v6 >"$ipv6_temp"

    # Verify downloads were successful
    if [ ! -s "$ipv4_temp" ] || [ ! -s "$ipv6_temp" ]; then
        echo -e "${RED}Failed to download Cloudflare IPs${NC}"
        return 1
    fi

    # Update Cloudflare IPs file
    echo "# Cloudflare IPv4 Ranges (Updated: $(date))" >"$CLOUDFLARE_IPS_FILE"
    cat "$ipv4_temp" >>"$CLOUDFLARE_IPS_FILE"
    echo -e "\n# Cloudflare IPv6 Ranges" >>"$CLOUDFLARE_IPS_FILE"
    cat "$ipv6_temp" >>"$CLOUDFLARE_IPS_FILE"

    # Cleanup
    rm -f "$ipv4_temp" "$ipv6_temp"

    chmod 600 "$CLOUDFLARE_IPS_FILE"
    return 0
}

# Function to apply whitelist using iptables
apply_whitelist() {
    # Flush existing rules
    iptables -F
    iptables -X
    ip6tables -F
    ip6tables -X

    # Default policy
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    ip6tables -P INPUT DROP
    ip6tables -P FORWARD DROP
    ip6tables -P OUTPUT ACCEPT

    # Allow localhost
    iptables -A INPUT -i lo -j ACCEPT
    ip6tables -A INPUT -i lo -j ACCEPT

    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Apply custom whitelist
    while read -r ip; do
        # Skip comments and empty lines
        [[ "$ip" =~ ^#|^$ ]] && continue

        if [[ "$ip" =~ ":" ]]; then
            ip6tables -A INPUT -s "$ip" -j ACCEPT
        else
            iptables -A INPUT -s "$ip" -j ACCEPT
        fi
    done <"$WHITELIST_FILE"

    # Apply Cloudflare IPs
    while read -r ip; do
        # Skip comments and empty lines
        [[ "$ip" =~ ^#|^$ ]] && continue

        if [[ "$ip" =~ ":" ]]; then
            ip6tables -A INPUT -s "$ip" -j ACCEPT
        else
            iptables -A INPUT -s "$ip" -j ACCEPT
        fi
    done <"$CLOUDFLARE_IPS_FILE"

    # Allow common ports
    for port in 22 80 443 445 444 81 1194; do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        ip6tables -A INPUT -p tcp --dport $port -j ACCEPT
    done

    # Save rules
    mkdir -p /etc/iptables
    iptables-save >/etc/iptables/rules.v4
    ip6tables-save >/etc/iptables/rules.v6

    # Ensure rules persist after reboot
    if [ ! -f /etc/systemd/system/iptables-restore.service ]; then
        cat >/etc/systemd/system/iptables-restore.service <<EOF
[Unit]
Description=Restore iptables rules
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4
ExecStart=/sbin/ip6tables-restore /etc/iptables/rules.v6
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable iptables-restore.service
    fi
}

# Create necessary directories and files
mkdir -p "$(dirname "$WHITELIST_FILE")"
touch "$WHITELIST_FILE"
chmod 600 "$WHITELIST_FILE"

# Main execution
echo -e "${YELLOW}Updating Cloudflare IP ranges...${NC}"
if get_cloudflare_ips; then
    echo -e "${GREEN}Cloudflare IP ranges updated successfully${NC}"
else
    echo -e "${RED}Failed to update Cloudflare IP ranges${NC}"
    exit 1
fi

echo -e "${YELLOW}Applying firewall rules...${NC}"
apply_whitelist

echo -e "${GREEN}Firewall rules applied successfully${NC}"
sleep 2
clear
