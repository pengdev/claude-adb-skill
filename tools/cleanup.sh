#!/usr/bin/env bash
# cleanup.sh — Remove temporary screenshot and UI dump files.
#
# Usage: cleanup.sh [OPTIONS]
#   -s, --serial SERIAL  Target device serial
#
# Removes:
#   Local:  /tmp/device_screenshot*.png /tmp/before_*.png /tmp/after_*.png
#           /tmp/step*.png /tmp/ui_dump*.xml
#   Device: /sdcard/screenshot_tmp.png /sdcard/ui_dump_tmp.xml

set -euo pipefail

SERIAL_FLAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--serial) SERIAL_FLAG="-s $2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Local cleanup
rm -f /tmp/device_screenshot*.png /tmp/before_*.png /tmp/after_*.png \
      /tmp/step*.png /tmp/ui_dump*.xml

# Device cleanup
adb $SERIAL_FLAG shell rm -f /sdcard/screenshot_tmp.png /sdcard/ui_dump_tmp.xml

echo "Cleanup complete."
