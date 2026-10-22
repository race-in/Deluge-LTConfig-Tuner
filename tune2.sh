#!/usr/bin/env bash
# Compatibility wrapper: use the maintained, validated tuner implementation.
set -Eeuo pipefail
SCRIPT_URL="https://raw.githubusercontent.com/race-in/Deluge-LTConfig-Tuner/main/tune.sh"
echo "The legacy tune2.sh is deprecated; handing off to the maintained tune.sh."
exec bash <(wget --https-only -qO- "$SCRIPT_URL")
