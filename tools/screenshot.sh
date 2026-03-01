#!/usr/bin/env bash
# screenshot.sh — Capture a screenshot from a connected Android device.
#
# Usage: screenshot.sh [OPTIONS]
#   -o, --output PATH    Local destination (default: /tmp/adb-skill/screenshot.png)
#   -d, --delay SECONDS  Sleep before capturing (default: 0)
#   -s, --serial SERIAL  Target device serial (for multi-device setups)
#
# Examples:
#   screenshot.sh
#   screenshot.sh -o /tmp/adb-skill/before_tap.png
#   screenshot.sh -d 2 -o /tmp/adb-skill/after_tap.png
#   screenshot.sh -s emulator-5554 -o /tmp/adb-skill/emu_screen.png

set -euo pipefail

OUTPUT="/tmp/adb-skill/screenshot.png"
DELAY=0
SERIAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      [[ $# -lt 2 ]] && { echo "Error: --output requires a value" >&2; exit 1; }
      OUTPUT="$2"; shift 2 ;;
    -d|--delay)
      [[ $# -lt 2 ]] && { echo "Error: --delay requires a value" >&2; exit 1; }
      DELAY="$2"; shift 2 ;;
    -s|--serial)
      [[ $# -lt 2 ]] && { echo "Error: --serial requires a value" >&2; exit 1; }
      SERIAL=(-s "$2"); shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

DEVICE_PATH="/sdcard/screenshot_tmp.png"

mkdir -p /tmp/adb-skill
sleep "$DELAY"

adb "${SERIAL[@]+"${SERIAL[@]}"}" shell screencap -p "$DEVICE_PATH"
adb "${SERIAL[@]+"${SERIAL[@]}"}" pull "$DEVICE_PATH" "$OUTPUT"
adb "${SERIAL[@]+"${SERIAL[@]}"}" shell rm -f "$DEVICE_PATH"

# Read PNG IHDR dimensions (stdlib only — no venv needed).
if command -v python3 &>/dev/null; then
    DIMENSIONS=$(python3 -c "
import struct, sys
with open(sys.argv[1], 'rb') as f:
    hdr = f.read(24)
    assert len(hdr) == 24 and hdr[:8] == b'\x89PNG\r\n\x1a\n'
    w, h = struct.unpack('>II', hdr[16:24])
    print(f'{w}x{h}')
" "$OUTPUT" 2>/dev/null) || DIMENSIONS="unknown"
else
    DIMENSIONS="unknown"
fi

if [[ "$DIMENSIONS" == "unknown" ]]; then
    echo "Warning: could not read PNG dimensions from $OUTPUT" >&2
fi
echo "$OUTPUT $DIMENSIONS"
