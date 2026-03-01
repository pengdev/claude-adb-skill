#!/usr/bin/env bash
# One-time setup: creates a Python venv with uiautomator2 and initializes the
# ATX agent on the connected device.
#
# Usage: setup.sh [OPTIONS]
#   -s, --serial SERIAL  Target device serial (for multi-device setups)
#
# NOTE: A device must be connected (adb devices) for the ATX agent init step.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
SERIAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--serial)
      [[ $# -lt 2 ]] && { echo "Error: --serial requires a value" >&2; exit 1; }
      SERIAL_ARGS=(--serial "$2"); shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ -d "$VENV_DIR" ]; then
    if ! "$VENV_DIR/bin/python3" -c "import uiautomator2; import PIL" 2>/dev/null; then
        echo "Existing venv is missing uiautomator2 or Pillow, recreating..."
        rm -rf "$VENV_DIR"
        python3 -m venv "$VENV_DIR"
    else
        echo "venv already exists at $VENV_DIR"
    fi
else
    echo "Creating venv at $VENV_DIR ..."
    python3 -m venv "$VENV_DIR"
fi

# find_colors.py depends on Pillow for image analysis.
# Pillow is also a transitive dep of uiautomator2, but we install it
# explicitly to avoid breakage if uiautomator2 ever drops it.
echo "Installing uiautomator2 and Pillow ..."
"$VENV_DIR/bin/pip" install --quiet uiautomator2 Pillow

echo "Initializing ATX agent on connected device ..."
"$VENV_DIR/bin/uiautomator2" init "${SERIAL_ARGS[@]+"${SERIAL_ARGS[@]}"}"
echo "Done. Multi-touch gestures and long-press are ready (gesture_helper.py)."
