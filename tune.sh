#!/usr/bin/env bash

#############################################################
# Deluge LTConfig Tuner
#
# Version : 0.1.0
# Author  : race-in
#
# Professional Deluge LTConfig Tuner
# Optimized for Private Tracker Racing
#############################################################

set -e

#######################################
# Script Information
#######################################

SCRIPT_NAME="Deluge LTConfig Tuner"
SCRIPT_VERSION="0.1.0"

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
# Global Variables
#######################################

USERNAME=""

CACHE_GIB=""
CACHE_LTCONFIG=""

CONFIG_DIR=""
CONFIG_FILE=""
BACKUP_FILE=""

SERVICE_NAME=""

#######################################
# Banner
#######################################

banner() {

    clear

    echo
    echo -e "${CYAN}============================================================${RESET}"
    echo -e "${WHITE}                 ${SCRIPT_NAME}${RESET}"
    echo -e "${WHITE}                     Version ${SCRIPT_VERSION}${RESET}"
    echo -e "${WHITE}         Optimized for Private Tracker Racing${RESET}"
    echo -e "${CYAN}============================================================${RESET}"
    echo

}

#######################################
# Root Check
#######################################

root_check() {

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR] Please run this script as root.${RESET}"
        exit 1
    fi

}

#######################################
# Debian Check
#######################################

debian_check() {

    source /etc/os-release

    case "$VERSION_CODENAME" in
        buster|bullseye|bookworm|trixie)
            ;;
        *)
            echo -e "${RED}[ERROR] Only Debian 10 / 11 / 12 / 13 is supported.${RESET}"
            exit 1
            ;;
    esac

}

#######################################
# Main
#######################################

main() {

    banner

    root_check

    debian_check

    echo -e "${GREEN}[ OK ] Framework Loaded Successfully${RESET}"

    echo

}

main
