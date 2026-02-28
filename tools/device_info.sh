#!/usr/bin/env bash
# device_info.sh — Wraps common device queries.
#
# Usage: device_info.sh [OPTIONS] <query>
#   -s, --serial SERIAL   Target device serial
#
# Queries:
#   list      → adb devices -l
#   size      → adb shell wm size
#   version   → adb shell getprop ro.build.version.release
#   model     → adb shell getprop ro.product.model
#   top       → adb shell dumpsys activity top
#
# Examples:
#   device_info.sh list
#   device_info.sh -s emulator-5554 size
#   device_info.sh model

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

QUERY="${1:?Usage: device_info.sh [OPTIONS] <query> (list|size|version|model|top)}"

case "$QUERY" in
  list)
    # -s is irrelevant for 'adb devices -l' (lists all devices); serial ignored
    if [[ ${#SERIAL[@]} -gt 0 ]]; then
      echo "Note: -s is ignored for 'list' (adb devices always lists all)" >&2
    fi
    adb devices -l
    ;;
  size)
    adb "${SERIAL[@]+"${SERIAL[@]}"}" shell wm size
    ;;
  version)
    adb "${SERIAL[@]+"${SERIAL[@]}"}" shell getprop ro.build.version.release
    ;;
  model)
    adb "${SERIAL[@]+"${SERIAL[@]}"}" shell getprop ro.product.model
    ;;
  top)
    adb "${SERIAL[@]+"${SERIAL[@]}"}" shell dumpsys activity top | head -100
    ;;
  *)
    echo "Unknown query: $QUERY (expected: list, size, version, model, top)" >&2
    exit 1
    ;;
esac
