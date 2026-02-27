#!/usr/bin/env bash
# logcat.sh — PID-filtered logcat with safe fallback.
#
# Usage: logcat.sh <package> [OPTIONS]
#   -d, --dump            Dump recent logs and exit (default: stream)
#   -t, --duration SECS   Timeout for streaming mode (default: 15)
#   -c, --clear           Clear logcat before capturing
#   --tags TAG1,TAG2      Fallback grep tags when PID unavailable
#   -s, --serial SERIAL   Target device serial
#
# Examples:
#   logcat.sh com.mapbox.maps           # Stream for 15s, PID-filtered
#   logcat.sh com.mapbox.maps -d        # Dump last 60s of logs
#   logcat.sh com.mapbox.maps -c -t 10  # Clear, then stream 10s
#   logcat.sh com.mapbox.maps --tags "MapboxMap,GL"

set -euo pipefail

PACKAGE="${1:?Usage: logcat.sh <package> [OPTIONS]}"
shift

DUMP=false
DURATION=15
CLEAR=false
TAGS=""
SERIAL_FLAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dump)     DUMP=true;       shift ;;
    -t|--duration) DURATION="$2";   shift 2 ;;
    -c|--clear)    CLEAR=true;      shift ;;
    --tags)        TAGS="$2";       shift 2 ;;
    -s|--serial)   SERIAL_FLAG="-s $2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if $CLEAR; then
  adb $SERIAL_FLAG logcat -c
fi

PID=$(adb $SERIAL_FLAG shell pidof "$PACKAGE" 2>/dev/null || true)

if $DUMP; then
  if [ -n "$PID" ]; then
    adb $SERIAL_FLAG logcat -d -t 60 --pid="$PID"
  else
    GREP_PATTERN="$PACKAGE"
    [ -n "$TAGS" ] && GREP_PATTERN="$PACKAGE|${TAGS//,/|}"
    adb $SERIAL_FLAG logcat -d -t 60 | grep -E "$GREP_PATTERN" || true
  fi
else
  if [ -n "$PID" ]; then
    timeout "$DURATION" adb $SERIAL_FLAG logcat --pid="$PID" || true
  else
    GREP_PATTERN="$PACKAGE"
    [ -n "$TAGS" ] && GREP_PATTERN="$PACKAGE|${TAGS//,/|}"
    timeout "$DURATION" adb $SERIAL_FLAG logcat | grep -E "$GREP_PATTERN" || true
  fi
fi
