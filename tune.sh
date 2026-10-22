#!/usr/bin/env bash
# Deluge LTConfig Tuner v1.0.2
set -Eeuo pipefail

SCRIPT_NAME="Deluge LTConfig Tuner"
SCRIPT_VERSION="1.0.2"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RESET='\033[0m'
USERNAME=""; USER_HOME=""; CACHE_GIB=""; CACHE_LTCONFIG=""; CONFIG_DIR=""; CONFIG_FILE=""; BACKUP_FILE=""; TEMP_FILE=""; SERVICE_STOPPED=0

cleanup() { [[ -z "$TEMP_FILE" ]] || rm -f -- "$TEMP_FILE"; }
recover_service() {
  local status=$?
  cleanup
  if (( status != 0 && SERVICE_STOPPED == 1 )); then
    echo "ERROR: Applying LTConfig failed. Attempting to restore the previous configuration." >&2
    if [[ -f "$BACKUP_FILE" ]]; then cp -af -- "$BACKUP_FILE" "$CONFIG_FILE"; chown "$USERNAME:$USERNAME" "$CONFIG_FILE"; fi
    systemctl start "deluged@$USERNAME" || echo "WARNING: Could not restart deluged@$USERNAME; start it manually." >&2
  fi
  exit "$status"
}
trap cleanup EXIT
trap recover_service ERR

banner() {
  printf '\n%b============================================================%b\n' "$CYAN" "$RESET"
  printf '%b               %s%b\n' "$WHITE" "$SCRIPT_NAME" "$RESET"
  printf '%b                    Version %s%b\n' "$WHITE" "$SCRIPT_VERSION" "$RESET"
  printf '%b============================================================%b\n\n' "$CYAN" "$RESET"
}
root_check() { [[ $EUID -eq 0 ]] || { echo "ERROR: Run as root." >&2; exit 1; }; }
debian_check() {
  local codename
  codename="$(sed -n 's/^VERSION_CODENAME=//p' /etc/os-release | head -n 1 | tr -d '"')"
  case "$codename" in buster|bullseye|bookworm|trixie) ;; *) echo "ERROR: Only Debian 10/11/12/13 are supported." >&2; exit 1;; esac
}
user_input() {
  read -r -p "Enter Deluge Username: " USERNAME
  id "$USERNAME" >/dev/null 2>&1 || { echo "ERROR: User '$USERNAME' not found." >&2; exit 1; }
  USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
  [[ -n "$USER_HOME" && -d "$USER_HOME" ]] || { echo "ERROR: Could not resolve a valid home directory for '$USERNAME'." >&2; exit 1; }
  CONFIG_DIR="$USER_HOME/.config/deluge"
  CONFIG_FILE="$CONFIG_DIR/ltconfig.conf"
  BACKUP_FILE="$CONFIG_FILE.bak"
  [[ -d "$CONFIG_DIR" ]] || { echo "ERROR: Deluge config directory not found: $CONFIG_DIR" >&2; exit 1; }

  read -r -p "Cache Size (GiB, 0 to disable): " CACHE_GIB
  [[ "$CACHE_GIB" =~ ^[0-9]+$ ]] || { echo "ERROR: Cache size must be a whole number." >&2; exit 1; }
  # LTConfig/libtorrent cache_size uses 16 KiB blocks. Bound input to avoid arithmetic overflow/unreasonable allocations.
  (( CACHE_GIB <= 1024 )) || { echo "ERROR: Cache size must be between 0 and 1024 GiB." >&2; exit 1; }
  CACHE_LTCONFIG=$((CACHE_GIB * 65536))
}
apply_ltconfig() {
  TEMP_FILE="$(mktemp "$CONFIG_DIR/.ltconfig.conf.XXXXXX")"
  wget --https-only -qO "$TEMP_FILE" "https://raw.githubusercontent.com/race-in/Deluge-LTConfig-Tuner/main/ltconfig.conf"
  [[ -s "$TEMP_FILE" ]] || { echo "ERROR: Downloaded LTConfig is empty." >&2; return 1; }
  # ltConfig preset format intentionally contains a metadata JSON object followed by a settings JSON object.
  grep -q '"apply_on_start"[[:space:]]*:[[:space:]]*true' "$TEMP_FILE" || { echo "ERROR: Downloaded file does not look like an LTConfig preset." >&2; return 1; }
  grep -q '"cache_size"[[:space:]]*:[[:space:]]*[0-9]' "$TEMP_FILE" || { echo "ERROR: cache_size is missing from LTConfig preset." >&2; return 1; }
  sed -Ei 's/("cache_size"[[:space:]]*:[[:space:]]*)[0-9]+/\1'"${CACHE_LTCONFIG}"'/' "$TEMP_FILE"
  chown "$USERNAME:$USERNAME" "$TEMP_FILE"
  chmod 0644 "$TEMP_FILE"
  [[ ! -f "$CONFIG_FILE" ]] || cp -af -- "$CONFIG_FILE" "$BACKUP_FILE"
  mv -f -- "$TEMP_FILE" "$CONFIG_FILE"
  TEMP_FILE=""
}
main() {
  banner
  root_check
  debian_check
  user_input
  systemctl stop "deluged@$USERNAME"
  SERVICE_STOPPED=1
  apply_ltconfig
  systemctl start "deluged@$USERNAME"
  SERVICE_STOPPED=0
  echo
  printf '%bLTConfig applied successfully.%b\n' "$GREEN" "$RESET"
  printf 'User        : %s\nCache (GiB) : %s\nConfig      : %s\n' "$USERNAME" "$CACHE_GIB" "$CONFIG_FILE"
}
main "$@"
