#!/usr/bin/env bash
# cleanup.sh — Remove temporary screenshot and UI dump files.
#
# Usage: cleanup.sh [OPTIONS] [extra_files...]
#   -s, --serial SERIAL  Target device serial
#
# Any extra arguments are treated as additional local files to remove.
#
# Removes:
#   Local:  /tmp/device_screenshot*.png /tmp/before_*.png /tmp/after_*.png
#           /tmp/step*.png /tmp/ui_dump*.xml  + any extra files passed as args
#   Device: /sdcard/screenshot_tmp.png /sdcard/ui_dump_tmp.xml

set -euo pipefail

SERIAL=()
EXTRA_FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--serial) SERIAL=(-s "$2"); shift 2 ;;
    *) EXTRA_FILES+=("$1"); shift ;;
  esac
done

# Local cleanup
rm -f /tmp/device_screenshot*.png /tmp/before_*.png /tmp/after_*.png \
      /tmp/step*.png /tmp/ui_dump*.xml "${EXTRA_FILES[@]+"${EXTRA_FILES[@]}"}"

# Device cleanup — non-fatal if device is unavailable
adb "${SERIAL[@]+"${SERIAL[@]}"}" shell rm -f /sdcard/screenshot_tmp.png /sdcard/ui_dump_tmp.xml || \
  echo "Warning: device cleanup skipped (device unavailable or ambiguous)" >&2

echo "Cleanup complete."
