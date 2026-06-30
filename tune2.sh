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
        "active_limit": -1,
        "active_seeds": -1,
        "active_tracker_limit": -1,
        "aio_max": 512,
        "aio_threads": 4,
        "allow_multiple_connections_per_ip": true,
        "allow_partial_disk_writes": true,
        "allowed_fast_set_size": 150,
        "announce_to_all_tiers": true,
        "announce_to_all_trackers": true,
        "auto_sequential": false,
        "cache_buffer_chunk_size": 0,
        "cache_expiry": 600,
        "cache_size": 131072,
        "choking_algorithm": 0,
        "close_redundant_connections": false,
        "coalesce_reads": true,
        "coalesce_writes": true,
        "connect_seed_every_n_download": 1,
        "connection_speed": 500,
        "connections_limit": 4000,
        "connections_slack": 500,
        "default_cache_min_age": 10,
        "disk_io_read_mode": 0,
        "disk_io_write_mode": 0,
        "enable_incoming_utp": false,
        "enable_outgoing_utp": false,
        "file_pool_size": 1000,
        "guided_read_cache": true,
        "handshake_timeout": 8,
        "hashing_threads": 2,
        "in_enc_policy": 2,
        "inactivity_timeout": 45,
        "initial_picker_threshold": 0,
        "lazy_bitfields": false,
        "listen_queue_size": 5000,
        "low_prio_disk": false,
        "max_allowed_in_request_queue": 100000,
        "max_failcount": 2,
        "max_out_request_queue": 3000,
        "max_peer_recv_buffer_size": 8388608,
        "max_queued_disk_bytes": 4294967296,
        "max_rejects": 5,
        "max_suggest_pieces": 100,
        "min_reconnect_time": 1,
        "mixed_mode_algorithm": 0,
        "no_atime_storage": true,
        "num_optimistic_unchoke_slots": 15,
        "num_want": 20,
        "optimistic_unchoke_interval": 5,
        "out_enc_policy": 2,
        "peer_connect_timeout": 5,
        "peer_timeout": 45,
        "peer_turnover": 5,
        "peer_turnover_cutoff": 80,
        "peer_turnover_interval": 180,
        "piece_timeout": 30,
        "predictive_piece_announce": 100,
        "prefer_rc4": false,
        "prioritize_partial_pieces": false,
        "rate_choker_initial_threshold": 256,
        "read_cache_line_size": 256,
        "recv_socket_buffer_size": 20971520,
        "request_queue_time": 3,
        "request_timeout": 120,
        "seed_choking_algorithm": 1,
        "seeding_outgoing_connections": true,
        "seeding_piece_quota": 1,
        "send_buffer_low_watermark": 104857600,
        "send_buffer_watermark": 1073741824,
        "send_buffer_watermark_factor": 1000,
        "send_not_sent_low_watermark": 1048576,
        "send_redundant_have": true,
        "send_socket_buffer_size": 20971520,
        "smooth_connects": false,
        "strict_end_game_mode": false,
        "suggest_mode": 1,
        "tick_interval": 25,
        "torrent_connect_boost": 255,
        "unchoke_interval": 5,
        "unchoke_slots_limit": -1,
        "upload_rate_limit": 0,
        "use_disk_cache_pool": true,
        "use_parole_mode": false,
        "whole_pieces_threshold": 3,
        "write_cache_line_size": 512
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
