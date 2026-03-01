#!/usr/bin/env bash
# find_colors.sh — Find colored elements in Android device screenshots.
#
# Wrapper that invokes find_colors.py via the skill's Python venv.
# Run setup.sh first to create the venv.
#
# Usage: find_colors.sh <image_path> [color_name] [options]
#   See find_colors.py --help for full options.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_PYTHON="$SCRIPT_DIR/.venv/bin/python3"

if [ ! -x "$VENV_PYTHON" ]; then
    echo "Error: venv not found at $SCRIPT_DIR/.venv/" >&2
    echo "Run setup.sh first: $SCRIPT_DIR/setup.sh" >&2
    exit 1
fi

exec "$VENV_PYTHON" "$SCRIPT_DIR/find_colors.py" "$@"
