#!/bin/bash
# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Path
SCRIPT_DIR="/root/vpn"
LOG_DIR="/root/vpn/logs"

# Function to view logs
view_logs() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Log Viewer"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Log viewing options
    echo -e "Log Viewing Options:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e " [1] VPN System Logs"
    echo -e " [2] Xray Service Logs"
    echo -e " [3] Nginx Logs"
    echo -e " [4] SSH Logs"
    echo -e " [5] System Journal Logs"
    echo -e " [6] Search Logs"
    echo -e " [7] Back to Menu"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select an option [1-7]: " log_option

    case $log_option in
    1)
        # VPN System Logs
        echo -e "\n${BLUE}VPN System Logs:${NC}"
        if [ -d "$LOG_DIR" ]; then
            tail -n 50 "$LOG_DIR"/*.log 2>/dev/null
        else
            echo -e "${RED}VPN log directory not found!${NC}"
        fi
        ;;

    2)
        # Xray Service Logs
        echo -e "\n${BLUE}Xray Service Logs:${NC}"
        journalctl -u xray | tail -n 50
        ;;

    3)
        # Nginx Logs
        echo -e "\n${BLUE}Nginx Access Logs:${NC}"
        tail -n 50 /var/log/nginx/access.log 2>/dev/null

        echo -e "\n${BLUE}Nginx Error Logs:${NC}"
        tail -n 50 /var/log/nginx/error.log 2>/dev/null
        ;;

    4)
        # SSH Logs
        echo -e "\n${BLUE}SSH Authentication Logs:${NC}"
        tail -n 50 /var/log/auth.log | grep sshd
        ;;

    5)
        # System Journal Logs
        echo -e "\n${BLUE}System Error Logs:${NC}"
        journalctl -p err -n 50
        ;;

    6)
        # Search Logs
        search_logs
        ;;

    7)
        return 0
        ;;

    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
    esac

    read -n 1 -s -r -p "Press any key to continue"
}

# Function to search logs
search_logs() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Log Search"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Prompt for search term
    read -p "Enter search term: " search_term

    if [ -z "$search_term" ]; then
        echo -e "${RED}Search term cannot be empty!${NC}"
        return 1
    fi

    # Search options
    echo -e "\nSearch Options:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e " [1] Search VPN Logs"
    echo -e " [2] Search System Logs"
    echo -e " [3] Search All Logs"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select search scope [1-3]: " search_scope

    case $search_scope in
    1)
        # Search VPN Logs
        if [ -d "$LOG_DIR" ]; then
            echo -e "\n${BLUE}Searching VPN Logs for '$search_term':${NC}"
            grep -n -R "$search_term" "$LOG_DIR"
        else
            echo -e "${RED}VPN log directory not found!${NC}"
        fi
        ;;

    2)
        # Search System Logs
        echo -e "\n${BLUE}Searching System Logs for '$search_term':${NC}"
        journalctl | grep -n "$search_term" | tail -n 50
        ;;

    3)
        # Search All Logs
        echo -e "\n${BLUE}Searching All Logs for '$search_term':${NC}"
        find /var/log/ -type f -print0 | xargs -0 grep -n "$search_term" 2>/dev/null | head -n 50
        ;;

    *)
        echo -e "${RED}Invalid search scope${NC}"
        ;;
    esac
}

# Real-time log monitoring function
monitor_logs() {
    clear
    echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
    echo -e " Real-time Log Monitor"
    echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

    # Log monitoring options
    echo -e "Real-time Monitoring Options:"
    echo -e "───────────────────────────────────────────────────────────"
    echo -e " [1] Monitor Xray Logs"
    echo -e " [2] Monitor Nginx Logs"
    echo -e " [3] Monitor SSH Logs"
    echo -e " [4] Monitor System Logs"
    echo -e " [5] Back to Menu"
    echo -e "───────────────────────────────────────────────────────────"
    read -p "Select an option [1-5]: " monitor_option

    case $monitor_option in
    1)
        echo -e "\n${BLUE}Real-time Xray Logs (Press CTRL+C to exit):${NC}"
        journalctl -u xray -f
        ;;

    2)
        echo -e "\n${BLUE}Real-time Nginx Access Logs (Press CTRL+C to exit):${NC}"
        tail -f /var/log/nginx/access.log
        ;;

    3)
        echo -e "\n${BLUE}Real-time SSH Logs (Press CTRL+C to exit):${NC}"
        tail -f /var/log/auth.log | grep sshd
        ;;

    4)
        echo -e "\n${BLUE}Real-time System Logs (Press CTRL+C to exit):${NC}"
        journalctl -f
        ;;

    5)
        return 0
        ;;

    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
    esac
}

# Main function to display log menu
log_menu() {
    while true; do
        clear
        echo -e "\033[1;34m╒═══════════════════════════════════════════════════════════╕\033[0m"
        echo -e " Log Management"
        echo -e "\033[1;34m╘═══════════════════════════════════════════════════════════╛\033[0m"

        echo -e "Log Management Options:"
        echo -e "───────────────────────────────────────────────────────────"
        echo -e " [1] View Logs"
        echo -e " [2] Search Logs"
        echo -e " [3] Real-time Log Monitor"
        echo -e " [4] Back to Main Menu"
        echo -e "───────────────────────────────────────────────────────────"
        read -p "Select an option [1-4]: " log_management_option

        case $log_management_option in
        1) view_logs ;;
        2) search_logs ;;
        3) monitor_logs ;;
        4) break ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 2
            ;;
        esac
    done
}

# Run the log menu
log_menu
