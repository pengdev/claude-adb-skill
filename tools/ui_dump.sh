#!/usr/bin/env bash
# ui_dump.sh — Dump the UI hierarchy from a connected Android device.
#
# Usage: ui_dump.sh [OPTIONS]
#   -o, --output PATH    Local destination (default: /tmp/adb-skill/ui_dump.xml)
#   -s, --serial SERIAL  Target device serial
#
# Examples:
#   ui_dump.sh
#   ui_dump.sh -o /tmp/adb-skill/ui_dump.xml

set -euo pipefail

OUTPUT="/tmp/adb-skill/ui_dump.xml"
SERIAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      [[ $# -lt 2 ]] && { echo "Error: --output requires a value" >&2; exit 1; }
      OUTPUT="$2"; shift 2 ;;
    -s|--serial)
      [[ $# -lt 2 ]] && { echo "Error: --serial requires a value" >&2; exit 1; }
      SERIAL=(-s "$2"); shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

DEVICE_PATH="/sdcard/ui_dump_tmp.xml"

mkdir -p /tmp/adb-skill
adb "${SERIAL[@]+"${SERIAL[@]}"}" shell uiautomator dump "$DEVICE_PATH"
adb "${SERIAL[@]+"${SERIAL[@]}"}" pull "$DEVICE_PATH" "$OUTPUT"
adb "${SERIAL[@]+"${SERIAL[@]}"}" shell rm -f "$DEVICE_PATH"

echo "$OUTPUT"
