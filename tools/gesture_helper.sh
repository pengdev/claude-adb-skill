#!/usr/bin/env bash
# gesture_helper.sh — Multi-touch and long-press gestures for Android devices.
#
# Wrapper that invokes gesture_helper.py via the skill's Python venv.
# Run setup.sh first to create the venv.
#
# Usage: gesture_helper.sh <gesture> [cx cy] [options]
#   See gesture_helper.py --help for full options.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_PYTHON="$SCRIPT_DIR/.venv/bin/python3"

if [ ! -x "$VENV_PYTHON" ]; then
    echo "Error: venv not found at $SCRIPT_DIR/.venv/" >&2
    echo "Run setup.sh first: $SCRIPT_DIR/setup.sh" >&2
    exit 1
fi

exec "$VENV_PYTHON" "$SCRIPT_DIR/gesture_helper.py" "$@"
