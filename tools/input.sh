#!/usr/bin/env bash
# input.sh — Wraps `adb shell input` with device targeting and optional delay.
#
# Usage: input.sh [OPTIONS] <command> [args...]
#   -s, --serial SERIAL   Target device serial
#   -d, --delay SECONDS   Sleep before executing (default: 0)
#
# Examples:
#   input.sh tap 500 800
#   input.sh -s emulator-5554 swipe 500 800 500 400 300
#   input.sh -s emulator-5554 text "hello"
#   input.sh keyevent KEYCODE_BACK
#   input.sh -d 1 tap 500 800              # wait 1s then tap
#   input.sh -d 1 -s emulator-5554 tap 500 800
#   input.sh -s emulator-5554 -d 1 tap 500 800  # -d/-s order is flexible

set -euo pipefail

SERIAL=()
DELAY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--serial)
      [[ $# -lt 2 ]] && { echo "Error: --serial requires a value" >&2; exit 1; }
      SERIAL=(-s "$2"); shift 2 ;;
    -d|--delay)
      [[ $# -lt 2 ]] && { echo "Error: --delay requires a value" >&2; exit 1; }
      if ! [[ "$2" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "Error: --delay must be a non-negative number, got: $2" >&2; exit 1
      fi
      DELAY="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) break ;;
  esac
done

if [[ $# -eq 0 ]]; then
  echo "Usage: input.sh [OPTIONS] <command> [args...]" >&2
  exit 1
fi

sleep "$DELAY"

# For 'text' subcommand, join all remaining args into a single string so
# spaces survive the adb shell boundary (adb splits on whitespace otherwise).
if [[ "${1:-}" == "text" ]] && [[ $# -ge 2 ]]; then
    shift
    adb "${SERIAL[@]+"${SERIAL[@]}"}" shell input text "$*"
else
    adb "${SERIAL[@]+"${SERIAL[@]}"}" shell input "$@"
fi
