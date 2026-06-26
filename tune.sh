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
# Main
#######################################

main() {

banner

root_check

debian_check

user_input

}

main
