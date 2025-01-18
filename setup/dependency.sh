#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Update package lists
echo -e "${YELLOW}Updating package lists...${NC}"
apt-get update -y

# Core system utilities
echo -e "${YELLOW}Installing core system utilities...${NC}"
apt-get install -y \
    wget \
    curl \
    git \
    unzip \
    zip \
    tar \
    htop \
    net-tools \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Network tools
echo -e "${YELLOW}Installing network tools...${NC}"
apt-get install -y \
    mtr \
    traceroute \
    netcat \
    dnsutils \
    speedtest-cli \
    vnstat

# Security tools
echo -e "${YELLOW}Installing security tools...${NC}"
apt-get install -y \
    fail2ban \
    ufw \
    openssl \
    certbot \
    python3-certbot-nginx

# Performance monitoring
echo -e "${YELLOW}Installing performance monitoring tools...${NC}"
apt-get install -y \
    sysstat \
    iotop \
    bmon

# Compression and archiving
echo -e "${YELLOW}Installing compression tools...${NC}"
apt-get install -y \
    p7zip-full \
    gzip \
    bzip2

# Development tools (for potential future scripting)
echo -e "${YELLOW}Installing development tools...${NC}"
apt-get install -y \
    build-essential \
    python3 \
    python3-pip

# Install required libraries
echo -e "${YELLOW}Installing additional libraries...${NC}"
apt-get install -y \
    libssl-dev \
    libpcre3 \
    libpcre3-dev \
    zlib1g-dev \
    libgd-dev

# Clean up
echo -e "${YELLOW}Cleaning up...${NC}"
apt-get autoremove -y
apt-get autoclean -y

# Enable services
systemctl enable vnstat
systemctl start vnstat

echo -e "${GREEN}System dependencies installation complete!${NC}"
