# ADB Skill for Claude Code

A [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills) that lets Claude operate on connected Android devices via ADB — install apps, view logs, take screenshots, tap UI elements, and perform multi-touch map gestures (pinch zoom, tilt, rotate) and long-press.

## Installation

Clone this repo into your Claude Code skills directory:

```bash
git clone https://github.com/pengdev/claude-adb-skill.git ~/.claude/skills/claude-adb-skill
```

## Requirements

- `adb` on your PATH (from Android SDK platform-tools)
- A connected Android device or emulator (`adb devices` shows it)
- Python 3 (for multi-touch gestures and long-press)
- `setup.sh` initializes the ATX agent on the connected device — a device must be connected when you run it

## Permissions

Adding permission rules to `~/.claude/settings.json` avoids repeated prompts during adb operations. Dangerous commands like `adb uninstall` and `adb shell pm clear` are intentionally excluded and will always prompt for confirmation.

Add the following to your `~/.claude/settings.json`:

```json
"permissions": {
  "allow": [
    "Bash(adb devices *)",
    "Bash(adb install *)",
    "Bash(adb shell input *)",
    "Bash(adb shell wm *)",
    "Bash(adb shell getprop *)",
    "Bash(adb shell dumpsys *)",
    "Bash(adb shell pm list *)",
    "Bash(adb shell am *)",
    "Bash(adb push *)",
    "Bash(*/skills/claude-adb-skill/tools/screenshot.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/logcat.sh *)",
    "Bash(*/skills/claude-adb-skill/tools/ui_dump.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/cleanup.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/gesture_helper.py *)",
    "Bash(*/skills/claude-adb-skill/tools/setup.sh*)",
    "Read(/tmp/*.png)",
    "Read(/tmp/ui_dump.xml)"
  ]
}
```

**What each rule covers:**

| Pattern | Purpose |
|---|---|
| `adb devices *` | Check connected devices |
| `adb install *` | Install APKs |
| `adb shell input *` | Tap, swipe, type text, key events |
| `adb shell wm *` | Get screen resolution |
| `adb shell getprop *` | Query device properties (model, OS version) |
| `adb shell dumpsys *` | Inspect current activity |
| `adb shell pm list *` | List installed packages |
| `adb shell am *` | Launch activities, force-stop apps |
| `adb push *` | Push files to device |
| `*/screenshot.sh*` | Capture + pull screenshot (wraps `screencap` + `pull`) |
| `*/logcat.sh *` | PID-filtered logcat with fallback (wraps `pidof` + `logcat`) |
| `*/ui_dump.sh*` | Dump + pull UI hierarchy (wraps `uiautomator` + `pull`) |
| `*/cleanup.sh*` | Remove temp files locally and on device |
| `*/gesture_helper.py *` | Multi-touch gestures and long-press |
| `*/setup.sh*` | One-time venv + ATX agent setup |
| `Read(/tmp/*.png)` | View pulled screenshots |
| `Read(/tmp/ui_dump.xml)` | View pulled UI hierarchy |

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
| **App lifecycle** | Install/uninstall APKs, launch activities, force-stop |
| **Build & deploy** | Build debug APK with Gradle, install on device |
| **Logcat** | PID-filtered log capture, live streaming with timeout, safe fallback when PID unavailable |
| **Files** | Push/pull files to/from device |
| **Screenshots** | Capture screen, view it visually, identify UI elements |
| **UI interaction** | Tap, swipe, long-press, type text, key events, UI hierarchy dump |
| **Map gestures** | Pan, double-tap zoom, pinch zoom in/out, tilt, rotate |

## Multi-Touch Gestures

Multi-touch (pinch, tilt, rotate) and long-press use [uiautomator2](https://github.com/openatx/uiautomator2) via a bundled Python helper. No root required.

One-time setup:

```bash
./tools/setup.sh
```
Run from the skill's root directory.

This creates a local `.venv/` with uiautomator2 installed and initializes the ATX agent on the connected device. A device must be connected for this step.

For multi-device setups, pass `--serial <serial>` (or `-s <serial>`) to `gesture_helper.py` to target a specific device.

## File Structure

```
SKILL.md                  # Skill instructions (loaded by Claude Code)
README.md                 # This file
tools/
  screenshot.sh           # Screenshot capture + pull
  logcat.sh               # PID-filtered logcat with safe fallback
  ui_dump.sh              # UI hierarchy dump + pull
  cleanup.sh              # Remove temp files (local + device)
  gesture_helper.py       # Gesture CLI (pinch, tilt, rotate, long-press)
  setup.sh                # One-time venv + ATX agent setup
  .venv/                  # Python venv (created by setup.sh, gitignored)
```
