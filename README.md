# Deluge LTConfig Tuner

A Bash utility for applying an LTConfig preset to Deluge. It supports root-managed `deluged@USERNAME` systemd services and non-root execution for the current user's own Deluge configuration.

> **Status: Under development.** Review the selected libtorrent settings for your installed Deluge/ltConfig plugin version and test on a non-production instance first.

## Features

- Debian 10, 11, 12 and 13 detection
- Root mode: selects a system user and stops/starts `deluged@USERNAME`
- Non-root mode: edits only the current user's `~/.config/deluge/ltconfig.conf`, without attempting privileged service control
- Backup of an existing `ltconfig.conf`
- Temporary download and basic preset validation before replacing the active file
- Cache size prompt (GiB), converted to libtorrent's 16 KiB cache blocks
- Error recovery that attempts to restore the backup if applying fails after the root-managed service was stopped

## Requirements

- Debian 10/11/12/13
- Bash, `wget`, `getent`, `grep`, `sed`, `mktemp`
- A valid system user with an existing writable `~/.config/deluge` directory
- A Deluge LTConfig plugin/config format compatible with the supplied preset
- Root mode additionally requires `systemctl` and a working `deluged@USERNAME` unit

## Install and run

### Root-managed Swizzin/systemd setup

Run as root:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/race-in/Deluge-LTConfig-Tuner/main/tune.sh)
```

The script asks for the Deluge system username and cache size in GiB. It stops and starts `deluged@USERNAME`.

### Non-root setup

Run as the same Linux user that owns the Deluge configuration:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/race-in/Deluge-LTConfig-Tuner/main/tune.sh)
```

Non-root mode only modifies the current user's configuration and does **not** use `sudo`, `systemctl`, or attempt to stop/restart Deluge. Restart that user's Deluge daemon manually after the script succeeds. The current user must have write access to `~/.config/deluge`.

Choose a cache size appropriate for available RAM and storage workload; do not allocate most of system memory to libtorrent cache.

## Safety notes

- The script downloads the preset from this repository's `main` branch. Inspect it before running if you need a pinned/reproducible configuration.
- Existing configuration is backed up to `ltconfig.conf.bak` before replacement.
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

MIT
