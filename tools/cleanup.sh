#!/usr/bin/env bash
# cleanup.sh — Remove temporary files created by the ADB skill.
#
# Usage: cleanup.sh [OPTIONS] [extra_files...]
#   -s, --serial SERIAL  Target device serial
#
# Any extra arguments are treated as additional local files to remove.
#
# Removes:
#   Local:  /tmp/adb-skill/  (entire directory) + any extra files passed as args
#   Device: /sdcard/screenshot_tmp.png /sdcard/ui_dump_tmp.xml

set -euo pipefail

SERIAL=()
EXTRA_FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--serial)
      [[ $# -lt 2 ]] && { echo "Error: --serial requires a value" >&2; exit 1; }
      SERIAL=(-s "$2"); shift 2 ;;
    *) EXTRA_FILES+=("$1"); shift ;;
  esac
done

# Local cleanup
rm -rf /tmp/adb-skill/
rm -f "${EXTRA_FILES[@]+"${EXTRA_FILES[@]}"}"

# Device cleanup — non-fatal if device is unavailable
adb "${SERIAL[@]+"${SERIAL[@]}"}" shell rm -f /sdcard/screenshot_tmp.png /sdcard/ui_dump_tmp.xml || \
  echo "Warning: device cleanup skipped (device unavailable or ambiguous)" >&2

# Kill the ATX agent to prevent "UiAutomationService already registered" on
# the next uiautomator2 session. The agent process lingers after a crash or
# abrupt session end and blocks re-initialization.
adb "${SERIAL[@]+"${SERIAL[@]}"}" shell am force-stop com.github.uiautomator 2>/dev/null || true

echo "Cleanup complete."
