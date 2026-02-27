#!/usr/bin/env bash
# ui_dump.sh — Dump the UI hierarchy from a connected Android device.
#
# Usage: ui_dump.sh [OPTIONS]
#   -o, --output PATH    Local destination (default: /tmp/ui_dump.xml)
#   -s, --serial SERIAL  Target device serial
#
# Examples:
#   ui_dump.sh
#   ui_dump.sh -o /tmp/my_dump.xml

set -euo pipefail

OUTPUT="/tmp/ui_dump.xml"
SERIAL_FLAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) OUTPUT="$2"; shift 2 ;;
    -s|--serial) SERIAL_FLAG="-s $2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

DEVICE_PATH="/sdcard/ui_dump_tmp.xml"

adb $SERIAL_FLAG shell uiautomator dump "$DEVICE_PATH"
adb $SERIAL_FLAG pull "$DEVICE_PATH" "$OUTPUT"
adb $SERIAL_FLAG shell rm -f "$DEVICE_PATH"

echo "$OUTPUT"
