#!/bin/bash
tput sgr0; clear

## Check Root Privilege
if [ "$(id -u)" -ne 0 ]; then
    echo "This script needs root permission to run"
    exit 1
fi

## Deluge Libtorrent Config
function Deluge_libtorrent {
    echo "Configuring Deluge Libtorrent Settings"

    if [ ! -d "/home/$username/.config/deluge" ]; then
        echo "Deluge config directory not found for user '$username'. Make sure Deluge is installed and has been run at least once."
        exit 1
    fi

    systemctl stop deluged@"$username"

    cat << EOF >/home/$username/.config/deluge/ltconfig.conf
{
  "file": 1, 
  "format": 1
}{
  "apply_on_start": true, 
  "settings": {
    "default_cache_min_age": 5, 
    "connection_speed": 1000, 
    "connections_limit": 3000, 
    "guided_read_cache": true, 
    "max_rejects": 100, 
    "inactivity_timeout": 120, 
    "active_seeds": -1, 
    "max_failcount": 20, 
    "allowed_fast_set_size": 0, 
    "max_allowed_in_request_queue": 10000, 
    "enable_incoming_utp": false, 
    "unchoke_slots_limit": -1, 
    "peer_timeout": 120, 
    "peer_connect_timeout": 30,
    "handshake_timeout": 30,
    "request_timeout": 5, 
    "allow_multiple_connections_per_ip": true, 
    "use_parole_mode": false, 
    "piece_timeout": 5, 
    "tick_interval": 100, 
    "active_limit": -1, 
    "connect_seed_every_n_download": 5, 
    "file_pool_size": 5000, 
    "cache_expiry": 60, 
    "seed_choking_algorithm": 1, 
    "max_out_request_queue": 10000, 
    "send_buffer_watermark": 10485760, 
    "send_buffer_watermark_factor": 200, 
    "active_tracker_limit": -1, 
    "send_buffer_low_watermark": 3145728, 
    "mixed_mode_algorithm": 0, 
    "max_queued_disk_bytes": 10485760, 
    "min_reconnect_time": 2,  
    "aio_threads": 4, 
    "write_cache_line_size": 256, 
    "torrent_connect_boost": 255, 
    "listen_queue_size": 3000, 
    "cache_buffer_chunk_size": 256, 
    "suggest_mode": 1, 
    "request_queue_time": 5, 
    "strict_end_game_mode": false, 
    "use_disk_cache_pool": true, 
    "predictive_piece_announce": 100, 
    "prefer_rc4": false, 
    "prioritize_partial_pieces": true, 
    "whole_pieces_threshold": 5, 
    "read_cache_line_size": 128, 
    "initial_picker_threshold": 2, 
    "enable_outgoing_utp": false, 
    "cache_size": $Cache1, 
    "low_prio_disk": false
  }
}
EOF

    chown "$username:$username" /home/$username/.config/deluge/ltconfig.conf

    systemctl start deluged@"$username"
    echo "Deluge libtorrent settings applied and service restarted."
}

## Prompt for input
read -p "Enter username of your Deluge: " username
if ! id "$username" >/dev/null 2>&1; then
    echo "User '$username' does not exist on this system."
    exit 1
fi

read -p "Cache Size (unit:GiB): " cache
if ! [[ "$cache" =~ ^[0-9]+$ ]]; then
    echo "Cache size must be a whole number (GiB)."
    exit 1
fi

# Convert GiB to libtorrent cache units (16KiB blocks): 1 GiB = 65536 blocks
Cache1=$(( cache * 65536 ))

Deluge_libtorrent
