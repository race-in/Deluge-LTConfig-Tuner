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
# Variables
#######################################

USERNAME=""
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
RESET='\033[0m'

#######################################
# Banner
#######################################

banner() {

clear

echo
echo -e "${CYAN}========================================================${RESET}"
echo -e "${GREEN}            Deluge LTConfig Tuner v1.0.0${RESET}"
echo -e "${CYAN}========================================================${RESET}"
echo

}

#######################################
# Root Check
#######################################

root_check() {

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERROR: Please run this script as root.${RESET}"
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
        echo -e "${RED}Unsupported Debian version.${RESET}"
        exit 1
        ;;
esac

}

#######################################
# User Input
#######################################

user_input() {

read -rp "Enter Deluge username: " USERNAME

read -rp "Cache Size (GiB): " CACHE_GIB

CACHE_LTCONFIG=$((CACHE_GIB * 65536))

CONFIG_DIR="/home/$USERNAME/.config/deluge"

CONFIG_FILE="$CONFIG_DIR/ltconfig.conf"

BACKUP_FILE="$CONFIG_DIR/ltconfig.conf.bak"

}

#######################################
# Validate
#######################################

validate_user() {

    if [[ ! -d "/home/$USERNAME" ]]; then
        echo -e "${RED}ERROR: User '$USERNAME' does not exist.${RESET}"
        exit 1
    fi

    if [[ ! -d "$CONFIG_DIR" ]]; then
        echo -e "${RED}ERROR: Deluge configuration not found.${RESET}"
        exit 1
    fi

}

#######################################
# Backup
#######################################

backup_ltconfig() {

    if [[ -f "$CONFIG_FILE" ]]; then
        cp -f "$CONFIG_FILE" "$BACKUP_FILE"
        echo -e "${GREEN}Backup created:${RESET} $BACKUP_FILE"
    fi

}

#######################################
# Stop Deluge
#######################################

stop_deluge() {

if ! systemctl stop "deluged@$USERNAME"; then
    echo -e "${RED}ERROR: Failed to stop Deluge.${RESET}"
    exit 1
fi

}

#######################################
# Install LTConfig
#######################################

install_ltconfig() {

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ ! -f "$SCRIPT_DIR/ltconfig.conf" ]]; then
        echo -e "${RED}ERROR: ltconfig.conf not found.${RESET}"
        exit 1
    fi

if ! cp -f "$SCRIPT_DIR/ltconfig.conf" "$CONFIG_FILE"; then
    echo -e "${RED}ERROR: Failed to install LTConfig.${RESET}"
    exit 1
fi

}

#######################################
# Update Cache Size
#######################################

update_cache() {

    if ! sed -i "s/\"cache_size\": *[0-9]\+/\"cache_size\": $CACHE_LTCONFIG/" "$CONFIG_FILE"; then
    echo -e "${RED}ERROR: Failed to update cache size.${RESET}"
    exit 1
fi

}

#######################################
# Start Deluge
#######################################

start_deluge() {

if ! systemctl start "deluged@$USERNAME"; then
    echo -e "${RED}ERROR: Failed to start Deluge.${RESET}"
    exit 1
fi

}

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

    echo
    echo -e "${GREEN}LTConfig installed successfully.${RESET}"
    echo

}

main

