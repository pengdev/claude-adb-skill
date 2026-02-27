---
name: adb
description: "Android Debug Bridge operations on connected devices. Use when the user wants to install/run apps, view logcat, take screenshots, interact with UI, or operate on a connected Android device."
argument-hint: "[command or description]"
---

# Android Debug Bridge (ADB) Operations

You help the user operate on connected Android devices via `adb`.

**SKILL_DIR**: The "Base directory for this skill" shown above when this skill is loaded. Use it to resolve all relative tool paths below (e.g. `$SKILL_DIR/tools/setup.sh`).

## Before Running Commands

- Run `adb devices -l` to confirm a device is connected.
- If multiple devices are connected, ask which one and use `adb -s <serial>`.

## Common Operations

**Device info:**
```bash
adb devices -l
adb shell wm size
adb shell getprop ro.build.version.release
adb shell getprop ro.product.model
```

**Install and launch apps:**
```bash
adb install -r path/to/app.apk
adb uninstall com.package.name
adb shell am start -n com.package.name/.ActivityName
adb shell am force-stop com.package.name
```

**Logcat — always use the logcat wrapper for PID-filtered output:**
```bash
# Dump recent logs (last 60s)
"$SKILL_DIR/tools/logcat.sh" com.package.name -d

# Stream for 15s (default)
"$SKILL_DIR/tools/logcat.sh" com.package.name

# Stream for 30s
"$SKILL_DIR/tools/logcat.sh" com.package.name -t 30

# Clear and stream (capture logs from a specific action)
"$SKILL_DIR/tools/logcat.sh" com.package.name -c -t 10

# Fallback grep tags when PID unavailable
"$SKILL_DIR/tools/logcat.sh" com.package.name --tags "MapboxMap,GL"
```
The script handles PID lookup and fallback automatically. When streaming live logs for a specific action, use `run_in_background` in the Bash tool, perform the action, then check the output.

**Files:**
```bash
adb pull /sdcard/path/on/device local_path
adb push local_path /sdcard/path/on/device
```

**App data:**
```bash
adb shell pm clear com.package.name
adb shell pm list packages | grep mapbox
adb shell dumpsys activity top
```

## Build & Deploy

When validating code changes on a device, build the APK before installing:

```bash
# Find the Gradle project root (look for build.gradle.kts or build.gradle)
# Build the debug APK for the target module
./gradlew <module>:assembleDebug

# The APK is at: <module>/build/outputs/apk/debug/<module>-debug.apk
adb install -r <module>/build/outputs/apk/debug/<module>-debug.apk
```

For multi-module projects, identify the app module (often `app/`) and build that.

## Screenshot and UI Interaction

**Take and view a screenshot:**
```bash
"$SKILL_DIR/tools/screenshot.sh"
"$SKILL_DIR/tools/screenshot.sh" -o /tmp/before_tap.png
"$SKILL_DIR/tools/screenshot.sh" -d 2 -o /tmp/after_tap.png   # 2s delay before capture
```
Then use the Read tool on the output path to view it. You are a multimodal LLM and can see the image.

Use descriptive filenames to distinguish screenshots taken at different points:
- `/tmp/before_tap.png`, `/tmp/after_tap.png`
- `/tmp/step1_home.png`, `/tmp/step2_detail.png`

This prevents overwriting and makes it easy to compare before/after states.

**Workflow for clicking a UI element:**
1. Take a screenshot: `"$SKILL_DIR/tools/screenshot.sh" -o /tmp/before_tap.png`
2. Read the screenshot with the Read tool to identify layout and coordinates
3. If coordinates are ambiguous, dump the UI hierarchy for exact bounds (see below)
4. Tap with `adb shell input tap <x> <y>`
5. Confirm the result: `"$SKILL_DIR/tools/screenshot.sh" -o /tmp/after_tap.png`

**UI hierarchy — get exact element bounds when visual estimation is uncertain:**
```bash
"$SKILL_DIR/tools/ui_dump.sh"
```
Then Read `/tmp/ui_dump.xml` to find elements by text, resource-id, or class. Each node has a `bounds` attribute like `[left,top][right,bottom]` — tap the center of the bounds rectangle.

**Input commands:**
```bash
adb shell input tap <x> <y>
adb shell input swipe <x1> <y1> <x2> <y2> <duration_ms>
adb shell input text "hello"
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_HOME
adb shell input keyevent KEYCODE_ENTER
```

**Cleanup:** After a task is complete, always clean up screenshots and temp files:
```bash
"$SKILL_DIR/tools/cleanup.sh"
```

## Map Gestures

### Before Any Gesture

1. Run `adb shell wm size` to get screen resolution
2. Take a screenshot (`"$SKILL_DIR/tools/screenshot.sh"`) and read it to identify the map area vs UI overlays (toolbars, FABs, bottom bars)
3. Compute the map center coordinates — target all gestures within the map area only

### Single-Touch Gestures (reliable)

**Double tap to zoom in:**
```bash
adb shell input tap <cx> <cy> && sleep 0.08 && adb shell input tap <cx> <cy>
```

**Long press** (e.g. to select a map point, drop a pin):
```bash
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" long_press <cx> <cy> --duration 1000
```

**Pan map:**
```bash
adb shell input swipe <cx> <cy> <cx> $((cy-300)) 300   # Pan up
adb shell input swipe <cx> <cy> <cx> $((cy+300)) 300   # Pan down
adb shell input swipe <cx> <cy> $((cx-300)) <cy> 300    # Pan left
adb shell input swipe <cx> <cy> $((cx+300)) <cy> 300    # Pan right
```

> **Note:** There is no single-touch zoom-out gesture. To zoom out, use `pinch_in` (multi-touch) below.

### Multi-Touch Gestures (via uiautomator2)

Multi-touch gestures use `$SKILL_DIR/tools/gesture_helper.py` with a local Python venv.

**Setup prerequisites:**
- A device must be connected — `setup.sh` installs the ATX agent on the device.
- For multi-device setups, pass `--serial <serial>` (or `-s <serial>`) to `gesture_helper.py`.

**Ensure the venv exists** (runs setup if missing):
```bash
[ -d "$SKILL_DIR/tools/.venv" ] || "$SKILL_DIR/tools/setup.sh"
```

**Invoke gestures:**
```bash
# Pinch zoom in (spread fingers outward)
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" pinch_out <cx> <cy> --radius 200 --steps 30

# Pinch zoom out (pinch fingers inward) — this is the only way to zoom out
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" pinch_in <cx> <cy> --radius 200 --steps 30

# Tilt map forward (two-finger swipe up)
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" tilt_up <cx> <cy> --radius 300 --steps 30

# Tilt map back (two-finger swipe down)
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" tilt_down <cx> <cy> --radius 300 --steps 30

# Rotate clockwise
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" rotate_cw <cx> <cy> --radius 200 --steps 30

# Rotate counter-clockwise
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" rotate_ccw <cx> <cy> --radius 200 --steps 30

# Long press (single-touch, configurable duration)
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" long_press <cx> <cy> --duration 2000

# Multi-device: pass --serial / -s
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" pinch_out <cx> <cy> -s <serial>
```

If `cx`/`cy` are omitted, screen center is used. Adjust `--radius` for gesture magnitude (larger = more zoom/tilt/rotation). Adjust `--steps` for smoothness (higher = smoother but slower).

## Tips

- When `INSTALL_FAILED_UPDATE_INCOMPATIBLE` occurs, uninstall the existing app first.
- Use `adb shell am start -n` with the fully qualified component name to launch exported activities.
- Parse and summarize logcat output — don't dump raw logs without explanation.
- Always take a screenshot before UI interaction to see the current state.
- For map gesture coordinates, compute actual pixel values from screen size and screenshot — don't hardcode.

## Recommended Permissions

Add these to `~/.claude/settings.json` under `permissions.allow` to avoid repeated prompts for standard operations. Dangerous commands (`adb uninstall`, `adb shell pm clear`) are intentionally excluded and will always prompt.

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
    "Bash([ -d *)",
    "Read(/tmp/*.png)",
    "Read(/tmp/ui_dump.xml)"
  ]
}
```
