/root/vpn/
├── setup/
│   ├── install.sh              # Script instalasi utama
│   ├── dependency.sh           # Instalasi paket yang dibutuhkan
│   ├── stunnel5.sh            # Instalasi & konfigurasi Stunnel5
│   ├── ssh.sh                 # Instalasi SSH & Dropbear
│   ├── xray.sh                # Instalasi Xray-core
│   ├── nginx.sh               # Instalasi & config Nginx
│   ├── ssl.sh                 # SSL certificate & Cloudflare manager
│   └── ip.sh                  # IP validator & manager
│
├── menu/
│   ├── menu.sh                # Menu utama
│   ├── ssh/
│   │   ├── menu.sh           # Menu SSH
│   │   ├── add.sh           # Tambah user SSH
│   │   ├── del.sh           # Hapus user SSH
│   │   ├── extend.sh        # Perpanjang user SSH
│   │   └── list.sh          # List user SSH
│   │
│   ├── vmess/
│   │   ├── menu.sh          # Menu Vmess
│   │   ├── add.sh           # Tambah user Vmess
│   │   ├── del.sh           # Hapus user Vmess
│   │   ├── extend.sh        # Perpanjang user Vmess
│   │   └── list.sh          # List user Vmess
│   │
│   ├── vless/
│   │   ├── menu.sh          # Menu Vless
│   │   ├── add.sh           # Tambah user Vless
│   │   ├── del.sh           # Hapus user Vless
│   │   ├── extend.sh        # Perpanjang user Vless
│   │   └── list.sh          # List user Vless
│   │
│   ├── trojan/
│   │   ├── menu.sh          # Menu Trojan
│   │   ├── add.sh           # Tambah user Trojan
│   │   ├── del.sh           # Hapus user Trojan
│   │   ├── extend.sh        # Perpanjang user Trojan
│   │   └── list.sh          # List user Trojan
│   │
│   ├── utility/
│   │   ├── menu.sh          # Menu Utility
│   │   ├── backup.sh        # Backup sistem
│   │   ├── restore.sh       # Restore sistem
│   │   ├── domain.sh        # Ganti domain
│   │   └── reboot.sh        # Reboot sistem
│   │
│   └── monitor/
│       ├── menu.sh          # Menu monitoring
│       ├── bandwidth.sh     # Monitor bandwidth
│       ├── cpu.sh           # Monitor CPU/RAM
│       └── log.sh           # View & clear logs
│
├── config/
│   ├── config.json          # Konfigurasi utama
│   ├── domain.conf          # Konfigurasi domain
│   ├── ip-whitelist.conf    # Daftar IP yang diizinkan
│   │
│   ├── xray/
│   │   ├── vmess.json       # Konfigurasi Vmess
│   │   ├── vless.json       # Konfigurasi Vless
│   │   └── trojan.json      # Konfigurasi Trojan
│   │
│   ├── nginx/
│   │   └── conf.d/
│   │       └── xray.conf    # Config Nginx untuk Xray
│   │
│   └── stunnel5/
│       ├── stunnel5.conf    # Konfigurasi Stunnel5
│       └── stunnel5.pem     # Certificate Stunnel5
│
├── cert/
│   ├── fullchain.pem        # SSL certificate
│   └── privkey.pem          # SSL private key
│
└── logs/
    ├── access.log           # Log akses
    ├── error.log            # Log error
    └── install.log          # Log instalasi

Port yang digunakan:
--------------------
1. SSH
   - OpenSSH: 22
   - Dropbear: 143, 109
   - SSH WS: 80
   - SSH WS SSL: 443

2. Stunnel5
   - OpenSSH: 447
   - Dropbear: 445
   - OpenVPN: 990

3. Xray
   - Vmess WS TLS: 443
   - Vmess WS: 80
   - Vless WS TLS: 443
   - Vless WS: 80
   - Trojan: 443

4. Nginx
   - HTTP: 80
   - HTTPS: 443

Package yang dibutuhkan:
-----------------------
1. Base System:
   - curl wget socat
   - net-tools
   - python3 python3-pip
   - cron
   - iptables
   - fail2ban
   - vnstat

2. Web Server:
   - nginx
   - apache2-utils

3. SSL & Security:
   - openssl
   - stunnel5 (compile from source)
   - certbot

4. SSH:
   - openssh-server
   - dropbear
   - squid
   - ws-epro

5. Xray:
   - xray-core
   - jq (JSON processor)

Service Management:
-----------------
1. Stunnel5:
   - Enable pada boot
   - Auto restart jika down
   - Monitor status

2. Xray:
   - Multi-user support
   - Auto backup config
   - Monitor performance

3. Nginx:
   - Reverse proxy untuk Xray
   - SSL termination
   - Web server untuk panel

4. Security:
   - IP whitelist
   - Fail2ban integration
   - Auto-ban malicious IP
