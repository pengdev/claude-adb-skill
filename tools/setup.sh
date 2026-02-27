#!/bin/bash
# One-time setup: creates a Python venv with uiautomator2 in the tools directory.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

if [ -d "$VENV_DIR" ]; then
    echo "venv already exists at $VENV_DIR"
else
    echo "Creating venv at $VENV_DIR ..."
    python3 -m venv "$VENV_DIR"
fi

echo "Installing uiautomator2 ..."
"$VENV_DIR/bin/pip" install --quiet uiautomator2
echo "Done. gesture_helper.py is ready to use."
