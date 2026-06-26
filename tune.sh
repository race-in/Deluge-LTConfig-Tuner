#!/usr/bin/env bash

#############################################################
# Deluge LTConfig Tuner
#
# Version : 1.0.0
# Author  : race-in
#
# GitHub:
# https://github.com/race-in/Deluge-LTConfig-Tuner
#############################################################

set -euo pipefail

#######################################
# Script Information
#######################################

SCRIPT_NAME="Deluge LTConfig Tuner"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#######################################
# Global Variables
#######################################

USERNAME=""
USER_HOME=""

CACHE_GIB=""
CACHE_LTCONFIG=""

CONFIG_DIR=""
CONFIG_FILE=""
BACKUP_FILE=""

#######################################
# Colors
#######################################

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

#######################################
# Banner
#######################################

banner() {

    clear

    echo
    echo -e "${CYAN}============================================================${RESET}"
    echo -e "${WHITE}               ${SCRIPT_NAME}${RESET}"
    echo -e "${WHITE}                    Version ${SCRIPT_VERSION}${RESET}"
    echo -e "${WHITE}        Optimized for Private Tracker Racing${RESET}"
    echo -e "${CYAN}============================================================${RESET}"
    echo

}

#######################################
# Root Check
#######################################

root_check() {

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}ERROR:${RESET} Please run this script as root."
        exit 1
    fi

}

#######################################
# Debian Check
#######################################

debian_check() {

    local codename

    codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"

    case "$codename" in
        buster|bullseye|bookworm|trixie)
            ;;
        *)
            echo -e "${RED}ERROR:${RESET} Only Debian 10/11/12/13 is supported."
            exit 1
            ;;
    esac

}

#######################################
# User Input
#######################################

user_input() {

    read -rp "Enter Deluge Username : " USERNAME

    while [[ -z "$USERNAME" ]]; do
        echo -e "${RED}Username cannot be empty.${RESET}"
        read -rp "Enter Deluge Username : " USERNAME
    done

    read -rp "Cache Size (GiB) : " CACHE_GIB

    while ! [[ "$CACHE_GIB" =~ ^[0-9]+$ ]]; do
        echo -e "${RED}Please enter a valid number.${RESET}"
        read -rp "Cache Size (GiB) : " CACHE_GIB
    done

    CACHE_LTCONFIG=$((CACHE_GIB * 65536))

    USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

    CONFIG_DIR="$USER_HOME/.config/deluge"

    CONFIG_FILE="$CONFIG_DIR/ltconfig.conf"

    BACKUP_FILE="$CONFIG_FILE.bak"

}

#######################################
# Validate User
#######################################

validate_user() {

    if ! id "$USERNAME" >/dev/null 2>&1; then
        echo -e "${RED}ERROR:${RESET} User '$USERNAME' does not exist."
        exit 1
    fi

    if [[ ! -d "$CONFIG_DIR" ]]; then
        echo -e "${RED}ERROR:${RESET} Deluge configuration not found."
        exit 1
    fi

    if [[ ! -f "$SCRIPT_DIR/ltconfig.conf" ]]; then
        echo -e "${RED}ERROR:${RESET} ltconfig.conf not found beside tune.sh."
        exit 1
    fi

}

#######################################
# Backup LTConfig
#######################################

backup_ltconfig() {

    if [[ -f "$CONFIG_FILE" ]]; then

        cp -f "$CONFIG_FILE" "$BACKUP_FILE"

        echo -e "${GREEN}Backup:${RESET} $BACKUP_FILE"

    fi

}

#######################################
# Stop Deluge
#######################################

stop_deluge() {

    echo -e "${YELLOW}Stopping Deluge...${RESET}"

    if ! systemctl stop "deluged@$USERNAME"; then
        echo -e "${RED}ERROR:${RESET} Failed to stop Deluge."
        exit 1
    fi

}

#######################################
# Install LTConfig
#######################################

install_ltconfig() {

    echo -e "${YELLOW}Installing LTConfig...${RESET}"

    if ! install -m 644 "$SCRIPT_DIR/ltconfig.conf" "$CONFIG_FILE"; then
        echo -e "${RED}ERROR:${RESET} Failed to install LTConfig."
        exit 1
    fi

}

#######################################
# Update Cache Size
#######################################

update_cache() {

    echo -e "${YELLOW}Updating Cache Size...${RESET}"

    if ! sed -Ei 's/("cache_size"[[:space:]]*:[[:space:]]*)[0-9]+/\1'"$CACHE_LTCONFIG"'/' "$CONFIG_FILE"; then
        echo -e "${RED}ERROR:${RESET} Failed to update cache_size."
        exit 1
    fi

}

#######################################
# Start Deluge
#######################################

start_deluge() {

    echo -e "${YELLOW}Starting Deluge...${RESET}"

    if ! systemctl start "deluged@$USERNAME"; then
        echo -e "${RED}ERROR:${RESET} Failed to start Deluge."
        exit 1
    fi

}

#######################################
# Success
#######################################

success() {

    echo
    echo -e "${CYAN}============================================================${RESET}"
    echo -e "${GREEN}LTConfig installed successfully.${RESET}"
    echo
    echo "User          : $USERNAME"
    echo "Cache (GiB)   : $CACHE_GIB"
    echo "Cache Value   : $CACHE_LTCONFIG"
    echo "Config File   : $CONFIG_FILE"
    echo "Backup File   : $BACKUP_FILE"
    echo -e "${CYAN}============================================================${RESET}"
    echo

}

#######################################
# Main
#######################################

main() {

    banner

    root_check

    debian_check

    user_input

    validate_user

    backup_ltconfig

    stop_deluge

    install_ltconfig

    update_cache

    start_deluge

    success

}

main
