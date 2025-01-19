#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories
VPN_DIR="/usr/local/vpn"
BACKUP_DIR="/var/backups/vpn"

# Function to print colored output
print_status() {
    if [ $2 -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    else
        echo -e "${RED}[FAILED]${NC} $1"
    fi
}

# Function to backup directory
backup_directory() {
    local dir=$1
    local backup_name="vpn_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

    mkdir -p "$BACKUP_DIR"
    echo -e "${YELLOW}Creating backup...${NC}"
    tar czf "$BACKUP_DIR/$backup_name" -C $(dirname "$dir") $(basename "$dir") 2>/dev/null
    if [ $? -eq 0 ]; then
        print_status "Backup created at $BACKUP_DIR/$backup_name" 0
    else
        print_status "Failed to create backup" 1
        exit 1
    fi
}

# Function to update script permissions
update_permissions() {
    local dir=$1
    echo -e "${YELLOW}Updating permissions...${NC}"
    find "$dir" -type d -exec chmod 700 {} \;
    find "$dir" -type f -name "*.sh" -exec chmod 500 {} \;
    find "$dir/config" -type f -exec chmod 600 {} \;
    find "$dir/cert" -type f -exec chmod 400 {} \;
    print_status "Permissions updated" $?
}

# Function to verify script integrity
verify_scripts() {
    local dir=$1
    local error_count=0

    echo -e "${YELLOW}Verifying scripts...${NC}"
    while IFS= read -r -d '' script; do
        bash -n "$script" 2>/dev/null
        if [ $? -ne 0 ]; then
            print_status "Syntax error in: $script" 1
            error_count=$((error_count + 1))
        fi
    done < <(find "$dir" -type f -name "*.sh" -print0)

    if [ $error_count -eq 0 ]; then
        print_status "All scripts verified" 0
        return 0
    else
        print_status "Found $error_count script(s) with errors" 1
        return 1
    fi
}

# Main update function
update_scripts() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi

    # Create backup
    backup_directory "$VPN_DIR"

    # Temporarily remove immutable attribute
    chattr -i "$VPN_DIR"/setup/*.sh 2>/dev/null
    chattr -i "$VPN_DIR"/menu/**/*.sh 2>/dev/null
    chattr -i "$VPN_DIR"/.installed 2>/dev/null

    # Update setup scripts
    for script in "$VPN_DIR/setup"/*.sh; do
        if [ -f "$script" ]; then
            touch -m "$script"
        fi
    done

    # Update menu scripts
    for category in ssh vmess vless trojan utility monitor; do
        if [ -d "$VPN_DIR/menu/$category" ]; then
            for script in "$VPN_DIR/menu/$category"/*.sh; do
                if [ -f "$script" ]; then
                    touch -m "$script"
                fi
            done
        fi
    done

    # Update configuration files
    for config_dir in xray nginx stunnel5; do
        if [ -d "$VPN_DIR/config/$config_dir" ]; then
            touch -m "$VPN_DIR/config/$config_dir"/* 2>/dev/null
        fi
    done

    # Update permissions
    update_permissions "$VPN_DIR"

    # Verify scripts
    verify_scripts "$VPN_DIR"
    if [ $? -eq 0 ]; then
        # Reset immutable attribute
        chattr +i "$VPN_DIR"/setup/*.sh 2>/dev/null
        chattr +i "$VPN_DIR"/menu/**/*.sh 2>/dev/null
        chattr +i "$VPN_DIR"/.installed 2>/dev/null

        # Restart services
        systemctl restart nginx xray stunnel5 dropbear ssh 2>/dev/null
        print_status "Services restarted" $?

        echo -e "${GREEN}Update completed!${NC}"
        sleep 2
        clear
    else
        echo -e "${RED}Update failed!${NC}"
        exit 1
    fi
}

# Run the update automatically
update_scripts
