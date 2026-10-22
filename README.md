# Deluge LTConfig Tuner

A Bash utility for applying an LTConfig preset to a Deluge daemon running as a systemd template service (`deluged@USERNAME`).

> **Status: Under development.** Review the selected libtorrent settings for your installed Deluge/ltConfig plugin version and test on a non-production instance first. This tool changes the user's LTConfig file and restarts the daemon.

## Features

- Debian 10, 11, 12 and 13 detection
- User-specific Deluge configuration path resolved from the system account database
- Backup of an existing `ltconfig.conf`
- Temporary download and validation before replacing the active file
- Cache size prompt (GiB), converted to libtorrent's 16 KiB cache blocks
- Error recovery that attempts to restore the backup and restart Deluge

## Requirements

- Debian 10/11/12/13
- Bash, `wget`, `systemctl`, `getent`, `grep`, `sed`, `mktemp`
- A valid system user with an existing `~/.config/deluge` directory
- A working `deluged@USERNAME` systemd unit
- Deluge LTConfig plugin/config format compatible with the supplied preset

## Install

Run as root:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/race-in/Deluge-LTConfig-Tuner/main/tune.sh)
```

The script asks for the Deluge system username and cache size in GiB. Choose a cache size appropriate for available RAM and storage workload; do not allocate most of system memory to libtorrent cache.

## Safety notes

- The script downloads the preset from this repository's `main` branch. Inspect it before running if you need a pinned/reproducible configuration.
- Existing configuration is backed up to `ltconfig.conf.bak` before replacement.
- If applying the preset fails after stopping the service, the script attempts to restore the backup and restart the service. Always verify service health after running.
- Cache size uses 16 KiB blocks: 1 GiB = 65,536 blocks.
- Settings such as peer limits, socket buffers, and timeouts are workload- and libtorrent-version-dependent; the preset is not guaranteed to be optimal for every server.
- Do not run the script on a production seedbox without a backup and maintenance window.

## Validation

```bash
bash -n tune.sh
bash -n tune2.sh
```

Shell syntax checks do not validate Deluge plugin compatibility or prove that every libtorrent setting is supported. Those require testing against the target Deluge/libtorrent versions.

## License

No license has been selected yet. Until a license is added, do not assume the project grants permission to redistribute or modify it.
