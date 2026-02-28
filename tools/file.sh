#!/usr/bin/env bash
# file.sh — Wraps file transfer between host and device.
#
# Usage: file.sh [OPTIONS] <action> <args...>
#   -s, --serial SERIAL   Target device serial
#
# Actions:
#   pull <device_path> [local_path]   → adb pull <device_path> [local_path]
#   push <local_path> <device_path>   → adb push <local_path> <device_path>
#
# Examples:
#   file.sh pull /sdcard/log.txt ./log.txt
#   file.sh -s emulator-5554 push local.txt /sdcard/local.txt
#   file.sh pull /sdcard/screenshot.png

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

ACTION="${1:?Usage: file.sh [OPTIONS] <pull|push> <args...>}"
shift

case "$ACTION" in
  pull)
    DEVICE_PATH="${1:?Missing device path}"
    shift
    adb "${SERIAL[@]+"${SERIAL[@]}"}" pull "$DEVICE_PATH" "$@"
    ;;
  push)
    LOCAL_PATH="${1:?Missing local path}"
    DEVICE_PATH="${2:?Missing device path}"
    if [[ ! -e "$LOCAL_PATH" ]]; then
      echo "Error: local path not found: $LOCAL_PATH" >&2; exit 1
    fi
    adb "${SERIAL[@]+"${SERIAL[@]}"}" push "$LOCAL_PATH" "$DEVICE_PATH"
    ;;
  *)
    echo "Unknown action: $ACTION (expected: pull, push)" >&2
    exit 1
    ;;
esac
