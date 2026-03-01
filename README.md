# ADB Skill for Claude Code

A [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills) that lets Claude operate on connected Android devices via ADB — install apps, view logs, take screenshots, tap UI elements, locate on-screen elements by color, and perform multi-touch map gestures (pinch zoom, tilt, rotate) and long-press.

## Installation

Clone this repo into your Claude Code skills directory:

```bash
git clone https://github.com/pengdev/claude-adb-skill.git ~/.claude/skills/claude-adb-skill
```

## Requirements

- `adb` on your PATH (from Android SDK platform-tools)
- A connected Android device or emulator (`adb devices` shows it)
- Python 3 (for multi-touch gestures, long-press, and color-based element finding)
- `setup.sh` initializes the ATX agent on the connected device — a device must be connected when you run it

## Permissions

Adding permission rules to `~/.claude/settings.json` avoids repeated prompts during adb operations. All standard adb access goes through wrapper scripts — dangerous commands like `adb uninstall`, `adb shell pm clear`, and `adb shell rm` are intentionally not wrapped and will always prompt for confirmation.

Add the following to your `~/.claude/settings.json`:

```json
"permissions": {
  "allow": [
    "Bash(*/skills/claude-adb-skill/tools/screenshot.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/logcat.sh *)",
    "Bash(*/skills/claude-adb-skill/tools/ui_dump.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/cleanup.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/setup.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/gesture_helper.sh *)",
    "Bash(*/skills/claude-adb-skill/tools/find_colors.sh *)",
    "Bash(*/skills/claude-adb-skill/tools/input.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/app.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/device_info.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/file.sh*)",
    "Read(/tmp/adb-skill-*)"
  ]
}
```

**What each rule covers:**

| Pattern | Purpose |
|---|---|
| `*/screenshot.sh*` | Capture + pull screenshot (wraps `screencap` + `pull`) |
| `*/logcat.sh *` | PID-filtered logcat with fallback — note trailing space enforces required package arg |
| `*/ui_dump.sh*` | Dump + pull UI hierarchy (wraps `uiautomator` + `pull`) |
| `*/cleanup.sh*` | Remove temp files locally and on device |
| `*/setup.sh*` | One-time venv + ATX agent setup |
| `*/gesture_helper.sh *` | Multi-touch gestures and long-press — trailing space enforces required gesture arg |
| `*/find_colors.sh *` | Color-based element finder — trailing space enforces required image arg |
| `*/input.sh*` | Tap, swipe, type text, key events (wraps `adb shell input`) |
| `*/app.sh*` | Install APKs, launch/stop apps, list packages (wraps `am` + `install` + `pm list`) |
| `*/device_info.sh*` | List devices, screen size, model, OS version, top activity |
| `*/file.sh*` | Pull/push files between host and device |
| `Read(/tmp/adb-skill-*)` | View pulled screenshots and UI hierarchy |

**Intentionally excluded** (will always prompt): `adb uninstall`, `adb shell pm clear`, `adb shell rm`.

## Usage Examples

Claude is a multimodal LLM — it can read screenshots to visually verify UI state, validate bug fixes against descriptions, and confirm layouts match design specs. Combined with ADB access, this means Claude can build, install, interact with, and visually inspect your app end-to-end.

The skill activates automatically when Claude detects a connected Android device is relevant to your task — no special command needed. You can also invoke it explicitly with `/adb` to start a device-focused session.

### Natural prompts (mid-session)

These work when you're already in a coding session — just ask Claude to validate on device:

**After fixing a bug:**
```
Try to validate the fix on device
```

**After a layout change:**
```
Build and install, then take a screenshot to check the layout looks right
```

**Investigating a crash:**
```
Install the debug build and stream logcat while I reproduce the crash
```

### Explicit `/adb` invocations

Use `/adb` when you want to start a standalone device interaction:

**Map gesture testing:**
```
/adb Open the map, pinch zoom in, tilt forward, rotate clockwise,
     and take screenshots at each step
```

**Device inspection:**
```
/adb Check what's running on the device and grab a screenshot
```

## What It Can Do

| Category | Examples |
|---|---|
| **Device management** | List devices, get device info, screen resolution |
| **App lifecycle** | Install APKs, launch/stop apps, list packages (via `app.sh`) |
| **Build & deploy** | Build debug APK with Gradle, install on device |
| **Logcat** | PID-filtered log capture, live streaming with timeout, safe fallback when PID unavailable |
| **Files** | Push/pull files to/from device (via `file.sh`) |
| **Screenshots** | Capture screen with dimensions, view it visually, identify UI elements |
| **UI interaction** | Tap, swipe, long-press, type text, key events (via `input.sh`), UI hierarchy dump |
| **Coordinate precision** | Find colored elements by pixel color (`find_colors.sh`), image-to-device coordinate scaling |
| **Map gestures** | Pan, double-tap zoom, pinch zoom in/out, tilt, rotate |

## Multi-Touch Gestures

Multi-touch (pinch, tilt, rotate) and long-press use [uiautomator2](https://github.com/openatx/uiautomator2) via a bundled Python helper. No root required.

One-time setup:

```bash
./tools/setup.sh
```
Run from the skill's root directory.

This creates a local `.venv/` with uiautomator2 and Pillow installed, and initializes the ATX agent on the connected device. A device must be connected for this step. If the venv becomes stale (e.g. after a Python version upgrade), `setup.sh` auto-detects and recreates the venv.

For multi-device setups, pass `--serial <serial>` (or `-s <serial>`) to `gesture_helper.sh` to target a specific device.

## File Structure

```
SKILL.md                  # Skill instructions (loaded by Claude Code)
README.md                 # This file
tools/
  screenshot.sh           # Screenshot capture + pull (with dimensions)
  logcat.sh               # PID-filtered logcat with safe fallback
  ui_dump.sh              # UI hierarchy dump + pull
  cleanup.sh              # Remove temp files (local + device)
  input.sh                # Input wrapper (tap, swipe, text, keyevent)
  app.sh                  # App lifecycle wrapper (start, stop, install, list)
  device_info.sh          # Device query wrapper (list, size, version, model, top)
  file.sh                 # File transfer wrapper (pull, push)
  gesture_helper.sh       # Gesture wrapper (pinch, tilt, rotate, long-press)
  gesture_helper.py       # Gesture implementation (Python, invoked by wrapper)
  find_colors.sh          # Color finder wrapper (invokes find_colors.py via venv)
  find_colors.py          # Color finder implementation (Python, uses Pillow)
  setup.sh                # One-time venv + ATX agent setup
  .venv/                  # Python venv (created by setup.sh, gitignored)
```
