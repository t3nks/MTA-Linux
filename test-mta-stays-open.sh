#!/usr/bin/env bash
# Run MTA client and verify it stays open for 2+ minutes without "Trouble serial-validation".
# Exit 0 only if: (1) MTA runs at least 2.5 min, and (2) report.log has no new Trouble serial / Core Quit.
# Usage: ./test-mta-stays-open.sh [path-to-mta-launcher]
set -e

LAUNCHER="${1:-$HOME/.local/bin/mta-san-andreas}"
COMPAT="${STEAM_COMPAT_DATA_PATH:-$HOME/.local/share/Steam/steamapps/compatdata/12120}"
REPORT_LOG="${COMPAT}/pfx/drive_c/ProgramData/MTA San Andreas All/1.6/report.log"
WAIT_SEC=150

if [[ ! -x "$LAUNCHER" ]]; then
  echo "Launcher not found or not executable: $LAUNCHER"
  exit 1
fi
if [[ ! -d "$COMPAT" ]]; then
  echo "Compat data not found: $COMPAT"
  exit 1
fi

# Line count before run (we only care about new lines)
INITIAL_LINES=0
[[ -f "$REPORT_LOG" ]] && INITIAL_LINES=$(wc -l < "$REPORT_LOG")

echo "Starting MTA (launcher=$LAUNCHER), waiting ${WAIT_SEC}s..."
"$LAUNCHER" &
PID=$!
trap 'kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null' EXIT

sleep "$WAIT_SEC"

# Check for Trouble serial / Core Quit in new report lines
FAIL=
if [[ -f "$REPORT_LOG" ]]; then
  NEW_FAIL=$(tail -n +"$((INITIAL_LINES+1))" "$REPORT_LOG" 2>/dev/null | grep -E "Trouble serial-validation|Core - Quit" || true)
  if [[ -n "$NEW_FAIL" ]]; then
    echo "FAIL: report.log shows serial validation failure in this run:"
    echo "$NEW_FAIL"
    FAIL=1
  fi
fi

# Check if MTA/gta_sa process is still running (client stayed up)
STILL_UP=
if pgrep -f "Multi Theft Auto|gta_sa.exe" >/dev/null 2>&1; then
  STILL_UP=1
fi

trap - EXIT
kill "$PID" 2>/dev/null
wait "$PID" 2>/dev/null || true

if [[ -n "$FAIL" ]]; then
  echo "Test FAILED: serial validation failed during run."
  exit 1
fi
if [[ -z "$STILL_UP" ]]; then
  echo "Test FAILED: MTA process exited before ${WAIT_SEC}s."
  exit 1
fi
echo "Test PASSED: MTA stayed open ${WAIT_SEC}s with no serial validation failure."
exit 0
