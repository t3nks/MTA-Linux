# MTA San Andreas on Linux (Steam + Proton)

Run **Multi Theft Auto (MTA) San Andreas** using your existing **GTA San Andreas** Steam install and Proton prefix. Fixes the "Unable to validate serial" error and sets up a launcher for Wolfi and other game launchers.

## What it does

1. **Download** – Fetches the official MTA 1.6 Windows installer (optional).
2. **Install** – Runs the installer inside the GTA SA Proton prefix (Steam app ID `12120`).
3. **Registry fix** – Adds the Rockstar Games serial keys so the game accepts the serial and no longer shows "Unable to validate serial".
4. **Launcher** – Installs `mta-san-andreas` and a desktop entry so you can start MTA from Wolfi, your app menu, etc.
5. **Steam shortcut** – Optionally adds MTA as a **non-Steam game** in Steam (pure shell; writes binary `shortcuts.vdf`). **Close Steam** before running so the shortcut is not overwritten.

## Requirements

- **Steam** with **Grand Theft Auto: San Andreas** (App ID `12120`) installed.
- **Proton** (e.g. Proton Hotfix, Proton 9.0 Beta). GTA SA must have been run at least once with Proton so the prefix exists.
- **bash**.
- For download: **curl** or **wget**.

## Quick start

```bash
git clone <your-repo-url> MTA-Linux && cd MTA-Linux
chmod +x MTA-linux.sh
./MTA-linux.sh
```

- The script will download the MTA installer, run it in the GTA SA prefix, apply the serial fix, and install the launcher.
- When the installer finishes, press Enter. Then run MTA via `mta-san-andreas` or from your launcher (e.g. Wolfi).
- **Serial:** The script **looks up** the serial from the prefix only (MTA or Rockstar registry). No user input and no env var.

## Usage

| Command | Description |
|--------|-------------|
| `./MTA-linux.sh` | Full run: download → install → fix → launcher |
| `./MTA-linux.sh --no-download` | Skip download; only apply fix and install launcher (MTA already installed) |
| `./MTA-linux.sh --installer /path/to/MTA_SA_1.6.0_setup.exe` | Use a local installer (no download) |
| `./MTA-linux.sh --skip-registry` | Don’t apply the serial registry fix |
| `./MTA-linux.sh --skip-launcher` | Don’t install the launcher script or desktop entry |
| `./MTA-linux.sh --skip-steam-shortcut` | Don't add MTA as a non-Steam game in Steam |
| `./MTA-linux.sh --help` | Show usage and options |

## Serial (lookup only)

The script **looks up** the serial from the prefix only. It does not hardcode a serial and does not ask the user to type or set one.

1. It checks (in order): MTA Settings in `system.reg`, MTA Settings in `user.reg`, Rockstar GTA San Andreas in `system.reg`, Rockstar in `user.reg`, then any 32‑char hex serial in the prefix.
2. If a serial is found, it is used for the Rockstar registry fix.
3. If none is found, the script exits and tells you to run GTA SA from Steam once, then run MTA once, then re-run the script with `--no-download` so it can look up the serial on the next run.

## Configuration (environment)

| Variable | Default | Description |
|----------|---------|-------------|
| `STEAM_ROOT` | `~/.local/share/Steam` | Steam root directory |
| `PROTON_NAME` | `Proton Hotfix` | Proton folder name under `steamapps/common/` |
| `MTA_INSTALLER_URL` | multitheftauto.com 1.6 installer | Installer URL (change if the default 404s) |
| `DOWNLOAD_DIR` | `~/Downloads` | Where to save the downloaded installer |

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
- **Serial error still appears** – Re-run with `--no-download` so the registry fix runs again; ensure you’re using the same prefix (Steam app 12120). The script writes the serial to both HKLM and HKCU.
- **"No serial found in prefix"** – Run GTA SA from Steam once, then run MTA once (so the prefix gets a serial), then run the script again with `--no-download` so it can look it up.
- **"There was a problem validating your serial" / "Serial verification failed"** – This happens **after** the client loads. The log shows **`[Error] Active steam process is unverified (pid: 65534)`**: MTA expects to run with a verified Steam process. If you launch MTA from our script (or a desktop shortcut) **without** Steam as the launcher, Steam is “unverified” and serial validation can fail. **Fix:** The script sets **`allow_steam_client=0`** in `MTA/config/coreconfig.xml` so MTA uses **registry serial only** (no Steam process check; under Proton there is no `steam.exe`). Re-run the script so it applies this change, then start MTA again (from Steam or the launcher).

## License

Script: use and modify as you like. MTA San Andreas and GTA San Andreas are their respective owners’ trademarks.
