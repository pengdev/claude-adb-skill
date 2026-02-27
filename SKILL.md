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

**Logcat — always filter by app PID to avoid noise:**
```bash
# Dump recent logs (non-blocking)
adb logcat -d -t 60 --pid=$(adb shell pidof com.package.name)
adb logcat -d -t 60 --pid=$(adb shell pidof com.package.name) | grep -iE "pattern1|pattern2"

# Stream live logs — use timeout to avoid hanging forever
timeout 15 adb logcat --pid=$(adb shell pidof com.package.name)

# Clear and stream (e.g. to capture logs from a specific action)
adb logcat -c && timeout 15 adb logcat --pid=$(adb shell pidof com.package.name)
```
When streaming live logs for a specific action, use `run_in_background` in the Bash tool, perform the action, then check the output.

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

## Screenshot and UI Interaction

**Take and view a screenshot:**
```bash
adb shell screencap -p /sdcard/screenshot.png && adb pull /sdcard/screenshot.png /tmp/device_screenshot.png
```
Then use the Read tool on `/tmp/device_screenshot.png` to view it. You are a multimodal LLM and can see the image.

**Workflow for clicking a UI element:**
1. Take a screenshot and pull it locally
2. Read the screenshot with the Read tool to identify layout and coordinates
3. If coordinates are ambiguous, dump the UI hierarchy for exact bounds (see below)
4. Tap with `adb shell input tap <x> <y>`
5. Take another screenshot to confirm the result

**UI hierarchy — get exact element bounds when visual estimation is uncertain:**
```bash
adb shell uiautomator dump /sdcard/ui_dump.xml && adb pull /sdcard/ui_dump.xml /tmp/ui_dump.xml
```
Then Read `/tmp/ui_dump.xml` to find elements by text, resource-id, or class. Each node has a `bounds` attribute like `[left,top][right,bottom]` — tap the center of the bounds rectangle. Clean up after: `adb shell rm /sdcard/ui_dump.xml && rm /tmp/ui_dump.xml`.

**Input commands:**
```bash
adb shell input tap <x> <y>
adb shell input swipe <x1> <y1> <x2> <y2> <duration_ms>
adb shell input text "hello"
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_HOME
adb shell input keyevent KEYCODE_ENTER
```

## Map Gestures

### Before Any Gesture

1. Run `adb shell wm size` to get screen resolution
2. Take a screenshot and read it to identify the map area vs UI overlays (toolbars, FABs, bottom bars)
3. Compute the map center coordinates — target all gestures within the map area only

### Single-Touch Gestures (reliable)

**Double tap to zoom in:**
```bash
adb shell input tap <cx> <cy> && sleep 0.08 && adb shell input tap <cx> <cy>
```

**Pan map:**
```bash
adb shell input swipe <cx> <cy> <cx> $((cy-300)) 300   # Pan up
adb shell input swipe <cx> <cy> <cx> $((cy+300)) 300   # Pan down
adb shell input swipe <cx> <cy> $((cx-300)) <cy> 300    # Pan left
adb shell input swipe <cx> <cy> $((cx+300)) <cy> 300    # Pan right
```

### Multi-Touch Gestures (via uiautomator2)

Multi-touch gestures use `$SKILL_DIR/tools/gesture_helper.py` with a local Python venv.

**Ensure the venv exists** (runs setup if missing):
```bash
[ -d "$SKILL_DIR/tools/.venv" ] || "$SKILL_DIR/tools/setup.sh"
```

**Invoke gestures:**
```bash
# Pinch zoom in (spread fingers outward)
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" pinch_out <cx> <cy> --radius 200 --steps 30

# Pinch zoom out (pinch fingers inward)
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" pinch_in <cx> <cy> --radius 200 --steps 30

# Tilt map forward (two-finger swipe up)
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" tilt_up <cx> <cy> --radius 300 --steps 30

# Tilt map back (two-finger swipe down)
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" tilt_down <cx> <cy> --radius 300 --steps 30

# Rotate clockwise
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" rotate_cw <cx> <cy> --radius 200 --steps 30

# Rotate counter-clockwise
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" rotate_ccw <cx> <cy> --radius 200 --steps 30
```

If `cx`/`cy` are omitted, screen center is used. Adjust `--radius` for gesture magnitude (larger = more zoom/tilt/rotation). Adjust `--steps` for smoothness (higher = smoother but slower).

## Tips

- When `INSTALL_FAILED_UPDATE_INCOMPATIBLE` occurs, uninstall the existing app first.
- Use `adb shell am start -n` with the fully qualified component name to launch exported activities.
- Parse and summarize logcat output — don't dump raw logs without explanation.
- Always take a screenshot before UI interaction to see the current state.
- For map gesture coordinates, compute actual pixel values from screen size and screenshot — don't hardcode.
- After a task is complete, clean up local screenshots (`rm /tmp/device_screenshot.png /tmp/before_*.png /tmp/after_*.png`) and on-device files (`adb shell rm /sdcard/screenshot.png`).
