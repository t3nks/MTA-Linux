# MTA San Andreas on Linux (Steam + Proton)

Workarounds to run **Multi Theft Auto (MTA) San Andreas** with your **GTA San Andreas** Steam install and Proton prefix. Applies registry and config changes that *may* address "Unable to validate serial"; **the only way to know it works is when the game stays open** (run `./test-mta-stays-open.sh` and it passes).

## What it does

1. **Download** – Fetches the official MTA 1.6 Windows installer (optional).
2. **Install** – Runs the installer inside the GTA SA Proton prefix (Steam app ID `12120`).
3. **Registry fix** – Writes the serial to HKCU and HKLM (Wow6432Node) so MTA can find it; also sets `allow_steam_client=0` and clears validation-failure markers.
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
| `PROTON_NAME` | `Proton 9.0 (Beta)` | Proton folder name under `steamapps/common/` |
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

## Testing

**Do not claim it works without running the test.** The only way to know MTA is fixed is if the game stays open. The test runs MTA for 2.5 minutes and fails if `report.log` shows "Trouble serial-validation" or "Core - Quit", or if the client exits.

```bash
./test-mta-stays-open.sh [path-to-mta-san-andreas]
```

Exit 0 = MTA stayed open with no serial validation failure. Exit 1 = failure.

## Verbose / debug logging

- **Proton + Wine log:** run with `MTA_VERBOSE=1`; output is written to `compatdata/12120/mta-launch.log`.
- **MTA debug log:** the launcher enables `debugfile` in `coreconfig.xml`; MTA writes to `MTA/logs/debug.log` inside the prefix (`pfx/drive_c/Program Files (x86)/MTA San Andreas 1.6/MTA/logs/debug.log`).
- **Report log:** `pfx/drive_c/ProgramData/MTA San Andreas All/1.6/report.log` – contains trouble codes (e.g. 3200 = serial-validation, 7101 = Core Quit).

## Troubleshooting

- **"Steam not found"** – Set `STEAM_ROOT` to your Steam root (e.g. `~/.steam/steam` or `~/.local/share/Steam`).
- **"Proton not found"** – Set `PROTON_NAME` to the Proton you use for GTA SA (e.g. `Proton 9.0 (Beta)`).
- **"GTA SA prefix not found"** – Install GTA San Andreas from Steam and launch it once with Proton.
- **Download fails** – Use `--installer /path/to/MTA_SA_1.6.0_setup.exe` with a manually downloaded installer.
- **Serial error still appears** – Re-run with `--no-download` so the registry fix runs again; ensure you’re using the same prefix (Steam app 12120). The script writes the serial to both HKLM and HKCU.
- **"No serial found in prefix"** – Run GTA SA from Steam once, then run MTA once (so the prefix gets a serial), then run the script again with `--no-download` so it can look it up.
- **"There was a problem validating your serial" / "Serial verification failed"** – The script sets **`allow_steam_client=0`** so MTA uses **registry serial only**. The launcher clears the `pending-browse-to-solution` marker each run so MTA retries. When launched from CLI or a desktop shortcut, MTA can still fail **online** serial validation after ~30s: `report.log` shows "Trouble serial-validation" and "Core - Quit"; registry gets `pending-browse-to-solution` with ecode **CN01**. **Try:** Launch MTA **from Steam** (Games → Add a non-Steam game → pick `mta-san-andreas` or the MTA desktop entry) so Steam is the parent process. Search the web for **"MTA San Andreas serial validation Linux"** or **"MTA CN01"** for community workarounds.

## License

Script: use and modify as you like. MTA San Andreas and GTA San Andreas are their respective owners’ trademarks.
