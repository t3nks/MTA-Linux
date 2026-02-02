# MTA San Andreas on Linux (Steam + Proton)

Run **Multi Theft Auto (MTA) San Andreas** using your existing **GTA San Andreas** Steam install and Proton prefix. Fixes the "Unable to validate serial" error and sets up a launcher for Wolfi and other game launchers.

## What it does

1. **Download** – Fetches the official MTA 1.6 Windows installer (optional).
2. **Install** – Runs the installer inside the GTA SA Proton prefix (Steam app ID `12120`).
3. **Registry fix** – Adds the Rockstar Games serial keys so the game accepts the serial and no longer shows "Unable to validate serial".
4. **Launcher** – Installs `mta-san-andreas` and a desktop entry so you can start MTA from Wolfi, your app menu, etc.

## Requirements

- **Steam** with **Grand Theft Auto: San Andreas** (App ID `12120`) installed.
- **Proton** (e.g. Proton Hotfix, Proton 9.0 Beta). GTA SA must have been run at least once with Proton so the prefix exists.
- **bash**.
- For download: **curl** or **wget**.

## Quick start

```bash
git clone <your-repo-url> GTA-SA-MTA && cd GTA-SA-MTA/SA
chmod +x MTA-linux.sh
./MTA-linux.sh
```

- The script will download the MTA installer, run it in the GTA SA prefix, apply the serial fix, and install the launcher.
- When the installer finishes, press Enter. Then run MTA via `mta-san-andreas` or from your launcher (e.g. Wolfi).

## Usage

| Command | Description |
|--------|-------------|
| `./MTA-linux.sh` | Full run: download → install → fix → launcher |
| `./MTA-linux.sh --no-download` | Skip download; only apply fix and install launcher (MTA already installed) |
| `./MTA-linux.sh --installer /path/to/MTA_SA_1.6.0_setup.exe` | Use a local installer (no download) |
| `./MTA-linux.sh --skip-registry` | Don’t apply the serial registry fix |
| `./MTA-linux.sh --skip-launcher` | Don’t install the launcher script or desktop entry |
| `./MTA-linux.sh --help` | Show usage and options |

## Configuration (environment)

| Variable | Default | Description |
|----------|---------|-------------|
| `STEAM_ROOT` | `~/.local/share/Steam` | Steam root directory |
| `PROTON_NAME` | `Proton Hotfix` | Proton folder name under `steamapps/common/` |
| `MTA_INSTALLER_URL` | multitheftauto.com 1.6 installer | Installer URL (change if the default 404s) |
| `DOWNLOAD_DIR` | `~/Downloads` | Where to save the downloaded installer |
| `MTA_SERIAL` | (script default) | Serial written to the registry (only change if you need a specific value) |

Example with custom Steam path:

```bash
STEAM_ROOT="$HOME/.steam/steam" ./MTA-linux.sh
```

## Installer URL

The script uses the official MTA 1.6 Windows installer URL. If that URL changes or returns 404:

- Set `MTA_INSTALLER_URL` when running, or  
- Download the installer from [multitheftauto.com](https://multitheftauto.com) and use `--installer /path/to/setup.exe`.

## What gets installed

- **Prefix:** MTA is installed into the existing GTA SA Proton prefix (`compatdata/12120`).
- **Launcher:** `~/.local/bin/mta-san-andreas` – run this to start MTA.
- **Desktop entry:** `~/.local/share/applications/MTA San Andreas.desktop` – shows up in app menus and launchers like Wolfi.

## Troubleshooting

- **"Steam not found"** – Set `STEAM_ROOT` to your Steam root (e.g. `~/.steam/steam` or `~/.local/share/Steam`).
- **"Proton not found"** – Set `PROTON_NAME` to the Proton you use for GTA SA (e.g. `Proton 9.0 (Beta)`).
- **"GTA SA prefix not found"** – Install GTA San Andreas from Steam and launch it once with Proton.
- **Download fails** – Use `--installer /path/to/MTA_SA_1.6.0_setup.exe` with a manually downloaded installer.
- **Serial error still appears** – Re-run with `--no-download` so the registry fix runs again; ensure you’re using the same prefix (Steam app 12120).

## License

Script: use and modify as you like. MTA San Andreas and GTA San Andreas are their respective owners’ trademarks.
