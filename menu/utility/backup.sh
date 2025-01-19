#!/bin/bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Backup Directory
BACKUP_BASE_DIR="/usr/local/vpn-backups"
SCRIPT_DIR="/usr/local/vpn"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_BASE_DIR"

# Function untuk backup
backup_system() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " System Backup"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Generate backup filename with timestamp
    BACKUP_FILENAME="vpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    BACKUP_PATH="$BACKUP_BASE_DIR/$BACKUP_FILENAME"

    # List of directories and files to backup
    BACKUP_SOURCES=(
        "$SCRIPT_DIR"
        "/etc/xray"
        "/etc/nginx"
        "/etc/ssh"
        "/etc/ssl/certs"
        "/root/.ssh"
    )

    # Backup configurations
    echo -e "${YELLOW}Creating system backup...${NC}"
    tar -czvf "$BACKUP_PATH" "${BACKUP_SOURCES[@]}" 2>/dev/null

    # Check if backup was successful
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Backup completed successfully!${NC}"
        echo -e "Backup file: $BACKUP_PATH"
        echo -e "Backup size: $(du -h "$BACKUP_PATH" | cut -f1)"
    else
        echo -e "${RED}Backup failed!${NC}"
    fi

    # Optional: Cleanup old backups (keep last 5)
    echo -e "${YELLOW}Cleaning up old backups...${NC}"
    ls -t "$BACKUP_BASE_DIR"/vpn-backup-* | tail -n +6 | xargs -I {} rm -f {}

    read -n 1 -s -r -p "Press any key to continue"
}

# Run backup function
backup_system
