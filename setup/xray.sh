#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
VPN_DIR="/usr/local/vpn"
CONFIG_DIR="$VPN_DIR/config"
XRAY_CONFIG_DIR="$CONFIG_DIR/xray"
CERT_DIR="$VPN_DIR/cert"

# Get latest Xray version
XRAY_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
ARCH=$(uname -m)

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Architecture mapping
get_arch() {
    case "$ARCH" in
    x86_64 | amd64) echo "64" ;;
    arm64 | aarch64) echo "arm64-v8a" ;;
    arm) echo "arm32-v7a" ;;
    *)
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
    esac
}

# Create necessary directories with proper permissions
setup_directories() {
    mkdir -p /usr/local/share/xray
    mkdir -p /etc/xray
    mkdir -p "$XRAY_CONFIG_DIR"
    mkdir -p /var/log/xray

    # Set correct permissions
    chmod 700 /usr/local/share/xray /etc/xray "$XRAY_CONFIG_DIR" /var/log/xray
}

# Install Xray
install_xray() {
    # Setup directories
    setup_directories

    # Determine architecture
    XRAY_ARCH=$(get_arch)

    # Download and install Xray
    cd /tmp
    wget -O xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip"
    unzip xray.zip -d /usr/local/share/xray
    chmod 700 /usr/local/share/xray/xray

    # Create symlink
    ln -sf /usr/local/share/xray/xray /usr/bin/xray

    # Cleanup
    rm -f /tmp/xray.zip
}

# Create systemd service
create_systemd_service() {
    cat >/etc/systemd/system/xray.service <<EOL
[Unit]
Description=Xray - A unified platform for anti-censorship
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
NoNewPrivileges=yes
ExecStart=/usr/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOL
}

# Create base configurations
create_base_configs() {
    # Main configuration
    cat >/etc/xray/config.json <<EOL
{
    "log": {
        "access": "/var/log/xray/access.log",
        "error": "/var/log/xray/error.log",
        "loglevel": "warning"
    },
    "api": {
        "tag": "api",
        "services": ["HandlerService", "LoggerService", "StatsService"]
    },
    "stats": {},
    "policy": {
        "levels": {
            "0": {
                "handshake": 4,
                "connIdle": 300,
                "uplinkOnly": 2,
                "downlinkOnly": 5,
                "statsUserUplink": true,
                "statsUserDownlink": true,
                "bufferSize": 4
            }
        },
        "system": {
            "statsInboundUplink": true,
            "statsInboundDownlink": true,
            "statsOutboundUplink": true,
            "statsOutboundDownlink": true
        }
    },
    "inbounds": [],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        },
        {
            "tag": "blocked",
            "protocol": "blackhole",
            "settings": {}
        }
    ],
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "outboundTag": "blocked",
                "ip": ["geoip:private"]
            },
            {
                "type": "field",
                "outboundTag": "blocked",
                "protocol": ["bittorrent"]
            }
        ]
    }
}
EOL
    chmod 600 /etc/xray/config.json

    # Create protocol configs
    for protocol in vmess vless trojan; do
        cat >"$XRAY_CONFIG_DIR/${protocol}.json" <<EOL
{
    "protocol": "${protocol}",
    "settings": {},
    "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
            "certificates": [
                {
                    "certificateFile": "${CERT_DIR}/fullchain.pem",
                    "keyFile": "${CERT_DIR}/privkey.pem"
                }
            ],
            "minVersion": "1.2",
            "cipherSuites": "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
        },
        "wsSettings": {
            "path": "/${protocol}",
            "headers": {}
        }
    }
}
EOL
        chmod 600 "$XRAY_CONFIG_DIR/${protocol}.json"
    done
}

# Configure log rotation
setup_log_rotation() {
    cat >/etc/logrotate.d/xray <<EOL
/var/log/xray/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    missingok
    postrotate
        systemctl restart xray
    endscript
}
EOL
}

# Main installation function
main() {
    # Install Xray
    install_xray

    # Create service
    create_systemd_service

    # Create configurations
    create_base_configs

    # Setup log rotation
    setup_log_rotation

    # Set proper permissions
    chown -R root:root /etc/xray
    chmod 700 /etc/xray
    chmod 600 /etc/xray/*

    # Start service
    systemctl daemon-reload
    systemctl enable xray
    systemctl restart xray

    clear
}

# Run installation
main
