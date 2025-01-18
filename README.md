# SMILANS VPN Server Setup

## 📁 Directory Structure

```
/root/vpn/
├── setup/                      # Installation Scripts
│   ├── install.sh             # Main installation script
│   ├── dependency.sh          # Package dependencies
│   ├── stunnel5.sh           # Stunnel5 installation
│   ├── ssh.sh                # SSH & Dropbear setup
│   ├── xray.sh               # Xray-core installation
│   ├── nginx.sh              # Nginx setup
│   ├── ssl.sh                # SSL & Cloudflare manager
│   └── ip.sh                 # IP whitelist manager
│
├── menu/                      # Menu Scripts
│   ├── menu.sh               # Main menu
│   │
│   ├── ssh/                  # SSH Management
│   │   ├── menu.sh          # SSH menu
│   │   ├── add.sh           # Add SSH user
│   │   ├── del.sh           # Delete SSH user
│   │   ├── extend.sh        # Extend SSH user
│   │   └── list.sh          # List SSH users
│   │
│   ├── vmess/               # Vmess Management
│   │   ├── menu.sh          # Vmess menu
│   │   ├── add.sh           # Add Vmess user
│   │   ├── del.sh           # Delete Vmess user
│   │   ├── extend.sh        # Extend Vmess user
│   │   └── list.sh          # List Vmess users
│   │
│   ├── vless/               # Vless Management
│   │   ├── menu.sh          # Vless menu
│   │   ├── add.sh           # Add Vless user
│   │   ├── del.sh           # Delete Vless user
│   │   ├── extend.sh        # Extend Vless user
│   │   └── list.sh          # List Vless users
│   │
│   ├── trojan/              # Trojan Management
│   │   ├── menu.sh          # Trojan menu
│   │   ├── add.sh           # Add Trojan user
│   │   ├── del.sh           # Delete Trojan user
│   │   ├── extend.sh        # Extend Trojan user
│   │   └── list.sh          # List Trojan users
│   │
│   ├── utility/             # Utility Tools
│   │   ├── menu.sh          # Utility menu
│   │   ├── backup.sh        # Backup system
│   │   ├── restore.sh       # Restore system
│   │   ├── domain.sh        # Domain management
│   │   └── reboot.sh        # System reboot
│   │
│   └── monitor/             # Monitoring Tools
│       ├── menu.sh          # Monitor menu
│       ├── bandwidth.sh     # Bandwidth monitor
│       ├── cpu.sh           # CPU/RAM monitor
│       └── log.sh           # Log viewer
│
├── config/                   # Configuration Files
│   ├── config.json          # Main config
│   ├── domain.conf          # Domain config
│   ├── ip-whitelist.conf    # IP whitelist
│   │
│   ├── xray/                # Xray Configs
│   │   ├── vmess.json       # Vmess config
│   │   ├── vless.json       # Vless config
│   │   └── trojan.json      # Trojan config
│   │
│   ├── nginx/               # Nginx Configs
│   │   └── conf.d/
│   │       └── xray.conf    # Xray nginx config
│   │
│   └── stunnel5/            # Stunnel5 Configs
│       ├── stunnel5.conf    # Stunnel config
│       └── stunnel5.pem     # Stunnel cert
│
├── cert/                    # SSL Certificates
│   ├── fullchain.pem        # SSL certificate
│   └── privkey.pem          # Private key
│
└── logs/                    # Log Files
    ├── access.log           # Access logs
    ├── error.log            # Error logs
    └── install.log          # Installation logs
```

## 🔌 Port Configuration

### SSH Ports

| Service    | Port     |
| ---------- | -------- |
| OpenSSH    | 22       |
| Dropbear   | 143, 109 |
| SSH WS     | 80       |
| SSH WS SSL | 443      |

### Stunnel5 Ports

| Service  | Port |
| -------- | ---- |
| OpenSSH  | 447  |
| Dropbear | 445  |
| OpenVPN  | 990  |

### Xray Ports

| Service      | Port |
| ------------ | ---- |
| Vmess WS TLS | 443  |
| Vmess WS     | 80   |
| Vless WS TLS | 443  |
| Vless WS     | 80   |
| Trojan       | 443  |

### Web Server Ports

| Service | Port |
| ------- | ---- |
| HTTP    | 80   |
| HTTPS   | 443  |

## 📦 Required Packages

### Base System

- curl wget socat
- net-tools
- python3 python3-pip
- cron
- iptables
- fail2ban
- vnstat

### Web Server

- nginx
- apache2-utils

### SSL & Security

- openssl
- stunnel5 (compiled from source)
- certbot

### SSH Services

- openssh-server
- dropbear
- squid
- ws-epro

### Xray

- xray-core
- jq (JSON processor)

## 🛠 Service Management

### Stunnel5

- [x] Enable on boot
- [x] Auto restart on failure
- [x] Status monitoring

### Xray

- [x] Multi-user support
- [x] Config backup
- [x] Performance monitoring

### Nginx

- [x] Xray reverse proxy
- [x] SSL termination
- [x] Web panel server

### Security

- [x] IP whitelist
- [x] Fail2ban integration
- [x] Malicious IP auto-ban

## 📝 Installation

```bash
git clone https://github.com/kayshinko/vpn-projeck.git /root/vpn
cd /root/vpn/setup
chmod +x install.sh
./install.sh
```

## 🔒 Security Notes

1. Always change default passwords
2. Regularly update allowed IP list
3. Monitor logs for suspicious activities
4. Keep all services updated

## 🌟 Features

- Easy user management
- Automatic security updates
- Performance monitoring
- Backup/Restore system
- Multi-protocol support
- IP whitelisting

## 📞 Support

- Developer: SMILANS
- Telegram: @XsSmilanSsX
