#!/bin/bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Backup Directory
BACKUP_BASE_DIR="/usr/local/vpn-backups"
SCRIPT_DIR="/usr/local/vpn"

# Function untuk restore
restore_system() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " System Restore"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Check if backup directory exists
    if [ ! -d "$BACKUP_BASE_DIR" ] || [ -z "$(ls -A "$BACKUP_BASE_DIR")" ]; then
        echo -e "${RED}No backups found!${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    # List available backups
    echo -e "${YELLOW}Available Backups:${NC}"
    backups=($(ls -t "$BACKUP_BASE_DIR"/vpn-backup-*.tar.gz))
    for i in "${!backups[@]}"; do
        printf "[%2d] %s\n" $((i + 1)) "$(basename "${backups[i]}")"
    done

    # Select backup
    read -p "Select backup to restore [1-${#backups[@]}]: " backup_choice

    # Validate selection
    if [[ ! "$backup_choice" =~ ^[0-9]+$ ]] ||
        [[ "$backup_choice" -lt 1 ]] ||
        [[ "$backup_choice" -gt "${#backups[@]}" ]]; then
        echo -e "${RED}Invalid selection!${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    # Adjust for zero-based index
    selected_backup="${backups[$((backup_choice - 1))]}"

    # Confirm restore
    echo -e "${YELLOW}WARNING: This will overwrite existing configurations!${NC}"
    read -p "Are you sure you want to restore from $(basename "$selected_backup")? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Restore cancelled.${NC}"
        read -n 1 -s -r -p "Press any key to continue"
        return 1
    fi

    # Create a pre-restore backup
    pre_restore_backup="$BACKUP_BASE_DIR/pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz"
    echo -e "${YELLOW}Creating pre-restore backup...${NC}"
    tar -czvf "$pre_restore_backup" "$SCRIPT_DIR" "/etc/xray" "/etc/nginx" "/etc/ssh" 2>/dev/null

    # Restore system
    echo -e "${YELLOW}Restoring system configuration...${NC}"

    # Stop services before restore
    systemctl stop xray nginx ssh

    # Extract backup
    tar -xzvf "$selected_backup" -C / 2>/dev/null

    # Restart services
    systemctl start xray nginx ssh

    # Check restore status
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Restore completed successfully!${NC}"
        echo -e "Pre-restore backup saved as: $pre_restore_backup"
        echo -e "Restored from: $(basename "$selected_backup")"
    else
        echo -e "${RED}Restore failed!${NC}"
        echo -e "Attempting to restore from pre-restore backup..."
        tar -xzvf "$pre_restore_backup" -C / 2>/dev/null
    fi

    read -n 1 -s -r -p "Press any key to continue"
}

# Run restore function
restore_system
