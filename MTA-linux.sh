#!/usr/bin/env bash
#
# MTA San Andreas – Linux setup for GTA SA Steam (Proton) prefix
#
# 1. Optionally downloads the MTA Windows installer and runs it in the GTA SA
#    Proton prefix (Steam app ID 12120).
# 2. Applies the "unable to validate serial" registry fix.
# 3. Installs the mta-san-andreas launcher script and desktop entry.
#
# Usage:
#   ./MTA-linux.sh                    # Download, install, fix, launcher
#   ./MTA-linux.sh --no-download      # Skip download; use existing prefix/install
#   ./MTA-linux.sh --installer PATH   # Use local installer exe (no download)
#   ./MTA-linux.sh --skip-registry   # Don't apply registry fix
#   ./MTA-linux.sh --skip-launcher   # Don't install launcher/desktop entry
#
# Requires: Steam, GTA San Andreas (12120) installed, Proton (e.g. Proton Hotfix).
# Optional: curl or wget (for download), protontricks (for install step).
#

set -e

# --- Config (override with env or edit) ---
STEAM_ROOT="${STEAM_ROOT:-$HOME/.local/share/Steam}"
COMPAT_DATA_PATH="${STEAM_ROOT}/steamapps/compatdata/12120"
PFX="${COMPAT_DATA_PATH}/pfx"
PROTON_NAME="${PROTON_NAME:-Proton Hotfix}"
PROTON="${STEAM_ROOT}/steamapps/common/${PROTON_NAME}/proton"
# Official MTA 1.6 Windows installer; set MTA_INSTALLER_URL if the default moves
# Current default from multitheftauto.com; fallback: download manually and use --installer
MTA_INSTALLER_URL="${MTA_INSTALLER_URL:-https://multitheftauto.com/dl/mtasa-1.6.0-setup.exe}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$HOME/Downloads}"
SERIAL="${MTA_SERIAL:-F1E43E4BE2B477B3C5EE8D85334E6392}"

# --- Flags ---
DO_DOWNLOAD=1
INSTALLER_PATH=
SKIP_REGISTRY=0
SKIP_LAUNCHER=0

# --- Help ---
usage() {
  sed -n '2,28p' "$0" | head -27
  echo ""
  echo "Options:"
  echo "  --no-download       Skip download; only fix registry and install launcher"
  echo "  --installer PATH    Use this local .exe as installer (no download)"
  echo "  --skip-registry     Do not apply the GTA serial registry fix"
  echo "  --skip-launcher     Do not install mta-san-andreas script or desktop entry"
  echo "  --help              Show this help"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-download)   DO_DOWNLOAD=0; shift ;;
    --installer)     INSTALLER_PATH="$2"; DO_DOWNLOAD=0; shift 2 ;;
    --skip-registry) SKIP_REGISTRY=1; shift ;;
    --skip-launcher) SKIP_LAUNCHER=1; shift ;;
    --help)          usage ;;
    *)               echo "Unknown option: $1"; usage ;;
  esac
done

# --- Checks ---
if [[ ! -d "$STEAM_ROOT" ]]; then
  echo "Steam not found at: $STEAM_ROOT (set STEAM_ROOT if needed)"
  exit 1
fi
if [[ ! -f "$PROTON" ]]; then
  echo "Proton not found at: $PROTON (set PROTON_NAME or path)"
  exit 1
fi
if [[ ! -d "$COMPAT_DATA_PATH" ]]; then
  echo "GTA SA prefix not found. Install GTA San Andreas (Steam app 12120) and run it once with Proton."
  exit 1
fi

export STEAM_COMPAT_DATA_PATH="$COMPAT_DATA_PATH"

# --- Download ---
installer_exe=
if [[ -n "$INSTALLER_PATH" ]]; then
  if [[ ! -f "$INSTALLER_PATH" ]]; then
    echo "Installer file not found: $INSTALLER_PATH"
    exit 1
  fi
  installer_exe="$INSTALLER_PATH"
  echo "Using local installer: $installer_exe"
elif [[ $DO_DOWNLOAD -eq 1 ]]; then
  mkdir -p "$DOWNLOAD_DIR"
  installer_exe="${DOWNLOAD_DIR}/MTA_SA_1.6.0_setup.exe"
  echo "Downloading MTA installer from: $MTA_INSTALLER_URL"
  if command -v curl &>/dev/null; then
    curl -L -o "$installer_exe" "$MTA_INSTALLER_URL" || {
      echo "Download failed. Try --installer /path/to/MTA_SA_1.6.0_setup.exe"
      exit 1
    }
  elif command -v wget &>/dev/null; then
    wget -O "$installer_exe" "$MTA_INSTALLER_URL" || {
      echo "Download failed. Try --installer /path/to/MTA_SA_1.6.0_setup.exe"
      exit 1
    }
  else
    echo "Need curl or wget to download. Use --installer /path/to/setup.exe or install curl/wget."
    exit 1
  fi
  echo "Downloaded: $installer_exe"
fi

# --- Run installer (if we have an exe) ---
if [[ -n "$installer_exe" ]]; then
  # Run installer in prefix; Proton sees host FS as Z:
  win_path="Z:${installer_exe//\//\\}"
  echo "Running MTA installer in GTA SA Proton prefix..."
  "$PROTON" runinprefix "$win_path" || true
  echo "If the installer did not run correctly, install MTA manually with:"
  echo "  STEAM_COMPAT_DATA_PATH=\"$COMPAT_DATA_PATH\" protontricks 12120 run <path-to-MTA-setup.exe>"
  echo ""
  read -r -p "Press Enter when the installer has finished (or to skip)..."
fi

# --- Registry fix (serial validation) ---
if [[ $SKIP_REGISTRY -eq 0 ]]; then
  echo "Applying GTA serial registry fix..."
  regfile="$(mktemp --suffix=.reg)"
  trap "rm -f $regfile" EXIT
  cat > "$regfile" <<EOF
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\\SOFTWARE\\Rockstar Games\\GTA San Andreas\\1.00.00001]
"Serial"="$SERIAL"

[HKEY_LOCAL_MACHINE\\SOFTWARE\\Rockstar Games\\GTA San Andreas\\Installation]
"exePath"="C:\\\\ProgramData\\\\MTA San Andreas All\\\\1.6\\\\GTA San Andreas\\\\gta_sa.exe"
"Installed"="1"

[HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Rockstar Games\\GTA San Andreas\\1.00.00001]
"Serial"="$SERIAL"

[HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Rockstar Games\\GTA San Andreas\\Installation]
"exePath"="C:\\\\ProgramData\\\\MTA San Andreas All\\\\1.6\\\\GTA San Andreas\\\\gta_sa.exe"
"Installed"="1"
EOF
  # Import with wine in the prefix (Z: = host root in Proton)
  win_reg="Z:${regfile//\//\\}"
  "$PROTON" runinprefix regedit /s "$win_reg" 2>/dev/null || {
    # Fallback: append to system.reg (Wine format)
    echo "Regedit import failed; appending to system.reg..."
    sysreg="${PFX}/system.reg"
    if [[ -f "$sysreg" ]]; then
      grep -q "Rockstar Games\\\\GTA San Andreas" "$sysreg" && echo "  (Rockstar keys already present)"
      if ! grep -q "Rockstar Games\\\\GTA San Andreas\\\\1.00.00001" "$sysreg"; then
        cat >> "$sysreg" <<SYSREG

[Software\\Rockstar Games\\GTA San Andreas\\1.00.00001] 1770030390
#time=1dc9433f9f716d0
"Serial"="$SERIAL"

[Software\\Rockstar Games\\GTA San Andreas\\Installation] 1770030390
#time=1dc9433f9f716d1
"exePath"="C:\\\\ProgramData\\\\MTA San Andreas All\\\\1.6\\\\GTA San Andreas\\\\gta_sa.exe"
"Installed"="1"

[Software\\Wow6432Node\\Rockstar Games\\GTA San Andreas\\1.00.00001] 1770030390
#time=1dc9433f9f716d0
"Serial"="$SERIAL"

[Software\\Wow6432Node\\Rockstar Games\\GTA San Andreas\\Installation] 1770030390
#time=1dc9433f9f716d1
"exePath"="C:\\\\ProgramData\\\\MTA San Andreas All\\\\1.6\\\\GTA San Andreas\\\\gta_sa.exe"
"Installed"="1"
SYSREG
        echo "  Appended Rockstar keys to system.reg"
      fi
    else
      echo "  system.reg not found; skip registry fix or run installer first."
    fi
  }
  rm -f "$regfile"
  trap - EXIT
  echo "Registry fix done."
fi

# --- Launcher script ---
if [[ $SKIP_LAUNCHER -eq 0 ]]; then
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/mta-san-andreas" <<LAUNCHER
#!/bin/sh
# Launch MTA using the GTA SA Proton prefix (12120)
STEAM_COMPAT_DATA_PATH="\$HOME/.local/share/Steam/steamapps/compatdata/12120"
PROTON="\$HOME/.local/share/Steam/steamapps/common/Proton Hotfix/proton"
MTA_EXE="C:\\\\Program Files (x86)\\\\MTA San Andreas 1.6\\\\Multi Theft Auto.exe"
export STEAM_COMPAT_DATA_PATH
exec "\$PROTON" runinprefix "\$MTA_EXE"
LAUNCHER
  chmod +x "$HOME/.local/bin/mta-san-andreas"
  echo "Installed: $HOME/.local/bin/mta-san-andreas"

  # Desktop entry
  mkdir -p "$HOME/.local/share/applications"
  cat > "$HOME/.local/share/applications/MTA San Andreas.desktop" <<DESKTOP
[Desktop Entry]
Name=MTA San Andreas
Comment=Multi Theft Auto - GTA San Andreas multiplayer (Proton)
Exec=$HOME/.local/bin/mta-san-andreas
Icon=steam_icon_12120
Terminal=false
Type=Application
Categories=Game;
StartupNotify=true
DESKTOP
  echo "Installed: $HOME/.local/share/applications/MTA San Andreas.desktop"

  if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  fi
  echo "Launcher and desktop entry installed. You can run MTA from Wolfi or: $HOME/.local/bin/mta-san-andreas"
fi

echo ""
echo "Done. Run MTA with: $HOME/.local/bin/mta-san-andreas (or from your launcher)."
