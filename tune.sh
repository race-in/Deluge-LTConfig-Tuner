#!/usr/bin/env bash
# Deluge LTConfig Tuner v1.0.0
set -euo pipefail

SCRIPT_NAME="Deluge LTConfig Tuner"
SCRIPT_VERSION="1.0.0"

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

USERNAME=""
USER_HOME=""
CACHE_GIB=""
CACHE_LTCONFIG=""
CONFIG_DIR=""
CONFIG_FILE=""
BACKUP_FILE=""

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

root_check() {
[[ $EUID -eq 0 ]] || { echo -e "${RED}ERROR:${RESET} Run as root."; exit 1; }
}

debian_check() {
local codename
codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
case "$codename" in
buster|bullseye|bookworm|trixie) ;;
*) echo -e "${RED}ERROR:${RESET} Only Debian 10/11/12/13 supported."; exit 1;;
esac
}

user_input() {
read -rp "Enter Deluge Username : " USERNAME
while [[ -z "$USERNAME" ]]; do
  read -rp "Enter Deluge Username : " USERNAME
done

read -rp "Cache Size (GiB) : " CACHE_GIB
while ! [[ "$CACHE_GIB" =~ ^[0-9]+$ ]]; do
  read -rp "Cache Size (GiB) : " CACHE_GIB
done

CACHE_LTCONFIG=$((CACHE_GIB * 65536))
USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

CONFIG_DIR="$USER_HOME/.config/deluge"
CONFIG_FILE="$CONFIG_DIR/ltconfig.conf"
BACKUP_FILE="$CONFIG_FILE.bak"
}

validate_user() {
id "$USERNAME" >/dev/null 2>&1 || { echo "User not found."; exit 1; }
[[ -d "$CONFIG_DIR" ]] || { echo "Deluge config not found."; exit 1; }
}

backup_ltconfig() {
[[ -f "$CONFIG_FILE" ]] && cp -af "$CONFIG_FILE" "$BACKUP_FILE"
}

stop_deluge() {
systemctl stop "deluged@$USERNAME"
}

apply_ltconfig() {
wget -qO "$CONFIG_FILE" "https://raw.githubusercontent.com/race-in/Deluge-LTConfig-Tuner/main/ltconfig.conf"
chown "$USERNAME:$USERNAME" "$CONFIG_FILE"
chmod 644 "$CONFIG_FILE"
}

update_cache() {
sed -Ei 's/("cache_size"[[:space:]]*:[[:space:]]*)[0-9]+/\1'"$CACHE_LTCONFIG"'/' "$CONFIG_FILE"
}

start_deluge() {
systemctl start "deluged@$USERNAME"
}

success() {
echo
echo -e "${GREEN}LTConfig applied successfully.${RESET}"
echo "User        : $USERNAME"
echo "Cache (GiB) : $CACHE_GIB"
echo "Config      : $CONFIG_FILE"
echo
}

main() {
banner
root_check
debian_check
user_input
validate_user
backup_ltconfig
stop_deluge
apply_ltconfig
update_cache
start_deluge
success
}

main
