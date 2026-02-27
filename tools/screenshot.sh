#!/usr/bin/env bash
# screenshot.sh — Capture a screenshot from a connected Android device.
#
# Usage: screenshot.sh [OPTIONS]
#   -o, --output PATH    Local destination (default: /tmp/device_screenshot.png)
#   -d, --delay SECONDS  Sleep before capturing (default: 0)
#   -s, --serial SERIAL  Target device serial (for multi-device setups)
#
# Examples:
#   screenshot.sh
#   screenshot.sh -o /tmp/step1_home.png
#   screenshot.sh -d 2 -o /tmp/after_tap.png
#   screenshot.sh -s emulator-5554 -o /tmp/emu_screen.png

set -euo pipefail

OUTPUT="/tmp/device_screenshot.png"
DELAY=0
SERIAL_FLAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) OUTPUT="$2"; shift 2 ;;
    -d|--delay)  DELAY="$2";  shift 2 ;;
    -s|--serial) SERIAL_FLAG="-s $2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

DEVICE_PATH="/sdcard/screenshot_tmp.png"

if (( $(echo "$DELAY > 0" | bc -l) )); then
  sleep "$DELAY"
fi

adb $SERIAL_FLAG shell screencap -p "$DEVICE_PATH"
adb $SERIAL_FLAG pull "$DEVICE_PATH" "$OUTPUT"
adb $SERIAL_FLAG shell rm -f "$DEVICE_PATH"

echo "$OUTPUT"
