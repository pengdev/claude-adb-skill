# ADB Skill for Claude Code

A [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills) that lets Claude operate on connected Android devices via ADB — install apps, view logs, take screenshots, tap UI elements, and perform multi-touch map gestures (pinch zoom, tilt, rotate).

## Installation

Clone this repo into your Claude Code skills directory:

```bash
git clone <repo-url> ~/.claude/skills/adb
```

## Requirements

- `adb` on your PATH (from Android SDK platform-tools)
- A connected Android device or emulator (`adb devices` shows it)
- Python 3 (for multi-touch gestures only)

## What It Can Do

| Category | Examples |
|---|---|
| **Device management** | List devices, get device info, screen resolution |
| **App lifecycle** | Install/uninstall APKs, launch activities, force-stop |
| **Logcat** | PID-filtered log capture, live streaming with timeout |
| **Files** | Push/pull files to/from device |
| **Screenshots** | Capture screen, view it visually, identify UI elements |
| **UI interaction** | Tap, swipe, type text, key events, UI hierarchy dump |
| **Map gestures** | Pan, double-tap zoom, pinch zoom in/out, tilt, rotate |

## Multi-Touch Gestures

Multi-touch (pinch, tilt, rotate) uses [uiautomator2](https://github.com/openatx/uiautomator2) via a bundled Python helper. No root required.

One-time setup:

```bash
./tools/setup.sh
```

This creates a local `.venv/` with uiautomator2 installed. The skill auto-runs setup if the venv is missing.

## File Structure

```
SKILL.md                  # Skill instructions (loaded by Claude Code)
README.md                 # This file
tools/
  gesture_helper.py       # Multi-touch gesture CLI (pinch, tilt, rotate)
  setup.sh                # One-time venv setup
  .venv/                  # Python venv (created by setup.sh, gitignored)
```
