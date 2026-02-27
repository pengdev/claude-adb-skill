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
SERIAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) OUTPUT="$2"; shift 2 ;;
    -d|--delay)  DELAY="$2";  shift 2 ;;
    -s|--serial) SERIAL=(-s "$2"); shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

DEVICE_PATH="/sdcard/screenshot_tmp.png"

sleep "$DELAY"

adb "${SERIAL[@]+"${SERIAL[@]}"}" shell screencap -p "$DEVICE_PATH"
adb "${SERIAL[@]+"${SERIAL[@]}"}" pull "$DEVICE_PATH" "$OUTPUT"
adb "${SERIAL[@]+"${SERIAL[@]}"}" shell rm -f "$DEVICE_PATH"

echo "$OUTPUT"
