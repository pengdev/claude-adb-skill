#!/usr/bin/env bash
# app.sh — Wraps app lifecycle commands (start, stop, install, list).
#
# Usage: app.sh [OPTIONS] <action> [args...]
#   -s, --serial SERIAL   Target device serial
#
# Actions:
#   start <component>     → adb shell am start -n <component>
#   stop <package>        → adb shell am force-stop <package>
#   install <apk_path>    → adb install -r <apk_path>
#   list [filter]         → adb shell pm list packages [| grep filter]
#
# Examples:
#   app.sh -s emulator-5554 start com.mapbox.maps/.MainActivity
#   app.sh stop com.mapbox.maps
#   app.sh install path/to/app.apk
#   app.sh list mapbox

set -euo pipefail

SERIAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--serial)
      [[ $# -lt 2 ]] && { echo "Error: --serial requires a value" >&2; exit 1; }
      SERIAL=(-s "$2"); shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) break ;;
  esac
done

ACTION="${1:?Usage: app.sh [OPTIONS] <action> [args...]}"
shift

case "$ACTION" in
  start)
    COMPONENT="${1:?Missing component (e.g. com.package/.Activity)}"
    adb "${SERIAL[@]+"${SERIAL[@]}"}" shell am start -n "$COMPONENT"
    ;;
  stop)
    PACKAGE="${1:?Missing package name}"
    adb "${SERIAL[@]+"${SERIAL[@]}"}" shell am force-stop "$PACKAGE"
    ;;
  install)
    APK="${1:?Missing APK path}"
    if [[ ! -f "$APK" ]]; then
      echo "Error: APK not found: $APK" >&2; exit 1
    fi
    adb "${SERIAL[@]+"${SERIAL[@]}"}" install -r "$APK"
    ;;
  list)
    FILTER="${1:-}"
    if [ -n "$FILTER" ]; then
      adb "${SERIAL[@]+"${SERIAL[@]}"}" shell pm list packages | grep -F "$FILTER" || true
    else
      adb "${SERIAL[@]+"${SERIAL[@]}"}" shell pm list packages
    fi
    ;;
  *)
    echo "Unknown action: $ACTION (expected: start, stop, install, list)" >&2
    exit 1
    ;;
esac
