---
name: adb
description: "Android Debug Bridge operations on connected devices. Use when the user wants to install/run apps, view logcat, take screenshots, interact with UI, or operate on a connected Android device."
argument-hint: "[command or description]"
---

# Android Debug Bridge (ADB) Operations

You help the user operate on connected Android devices via `adb`.

**SKILL_DIR**: The "Base directory for this skill" shown above when this skill is loaded. Use it to resolve all relative tool paths below (e.g. `$SKILL_DIR/tools/setup.sh`).

## Before Running Commands

- Run `"$SKILL_DIR/tools/device_info.sh" list` to confirm a device is connected.
- If multiple devices are connected, ask which one and pass `-s <serial>` to ALL tool scripts and raw `adb` commands consistently throughout the session.

## Common Operations

**Device info:**
```bash
"$SKILL_DIR/tools/device_info.sh" list
"$SKILL_DIR/tools/device_info.sh" size
"$SKILL_DIR/tools/device_info.sh" version
"$SKILL_DIR/tools/device_info.sh" model

# Multi-device:
"$SKILL_DIR/tools/device_info.sh" -s <serial> size
```

**Install and launch apps:**
```bash
"$SKILL_DIR/tools/app.sh" install path/to/app.apk
adb uninstall com.package.name
"$SKILL_DIR/tools/app.sh" start com.package.name/.ActivityName
"$SKILL_DIR/tools/app.sh" stop com.package.name

# Multi-device:
"$SKILL_DIR/tools/app.sh" -s <serial> install path/to/app.apk
"$SKILL_DIR/tools/app.sh" -s <serial> start com.package.name/.ActivityName
```

**Logcat — always use the logcat wrapper for PID-filtered output:**
```bash
# Dump recent logs (last 60 lines)
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
"$SKILL_DIR/tools/file.sh" pull /sdcard/path/on/device local_path
"$SKILL_DIR/tools/file.sh" push local_path /sdcard/path/on/device

# Multi-device:
"$SKILL_DIR/tools/file.sh" -s <serial> pull /sdcard/path/on/device local_path
```

**App data:**
```bash
adb shell pm clear com.package.name
"$SKILL_DIR/tools/app.sh" list mapbox
"$SKILL_DIR/tools/device_info.sh" top    # returns first 100 lines; use raw adb for full output
```

## Build & Deploy

When validating code changes on a device, build the APK before installing:

```bash
# Find the Gradle project root (look for build.gradle.kts or build.gradle)
# Build the debug APK for the target module
./gradlew <module>:assembleDebug

# The APK is at: <module>/build/outputs/apk/debug/<module>-debug.apk
"$SKILL_DIR/tools/app.sh" install <module>/build/outputs/apk/debug/<module>-debug.apk
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
4. Tap with `"$SKILL_DIR/tools/input.sh" tap <x> <y>`
5. Confirm the result: `"$SKILL_DIR/tools/screenshot.sh" -o /tmp/after_tap.png`

**UI hierarchy — get exact element bounds when visual estimation is uncertain:**
```bash
"$SKILL_DIR/tools/ui_dump.sh"
```
Then Read `/tmp/ui_dump.xml` to find elements by text, resource-id, or class. Each node has a `bounds` attribute like `[left,top][right,bottom]` — tap the center of the bounds rectangle.

**Input commands:**
```bash
"$SKILL_DIR/tools/input.sh" tap <x> <y>
"$SKILL_DIR/tools/input.sh" swipe <x1> <y1> <x2> <y2> <duration_ms>
"$SKILL_DIR/tools/input.sh" text "hello"
"$SKILL_DIR/tools/input.sh" keyevent KEYCODE_BACK
"$SKILL_DIR/tools/input.sh" keyevent KEYCODE_HOME
"$SKILL_DIR/tools/input.sh" keyevent KEYCODE_ENTER

# Wait before input (e.g. after animation):
"$SKILL_DIR/tools/input.sh" -d 1 tap <x> <y>

# Multi-device:
"$SKILL_DIR/tools/input.sh" -s <serial> tap <x> <y>
"$SKILL_DIR/tools/input.sh" -d 1 -s <serial> tap <x> <y>
"$SKILL_DIR/tools/input.sh" -s <serial> -d 1 tap <x> <y>  # -d/-s order is flexible
```

**Cleanup:** After a task is complete, always clean up screenshots and temp files:
```bash
# Single device:
"$SKILL_DIR/tools/cleanup.sh"

# Multi-device:
"$SKILL_DIR/tools/cleanup.sh" -s <serial>
```

## Coordinate Precision

**The problem:** The Read tool may display screenshots at different resolution than the original device capture. Visually estimating pixel coordinates from a resized image introduces systematic offset errors that compound with repeated gestures (especially double-tap zoom, which re-centers on the tap point).

**Coordinate calculation workflow:**
1. Get device screen size: `"$SKILL_DIR/tools/device_info.sh" size` → e.g., `1080x2400`
2. Take screenshot — note the reported `WxH` from output: `"$SKILL_DIR/tools/screenshot.sh"` → `/tmp/device_screenshot.png 2960x1848`
3. Get UI container bounds: `"$SKILL_DIR/tools/ui_dump.sh"` → find the MapView bounds `[L,T][R,B]` in `/tmp/ui_dump.xml`
4. Locate the target:
   - **For colored elements** (markers, clusters, icons): use `find_colors.py` (see below)
   - **For UI elements**: use bounds from `ui_dump.xml`
   - **For estimated positions**: express as a fraction of the container, then multiply by device dimensions
5. Convert image coordinates to device coordinates:
   ```
   scale_x = device_width / image_width
   scale_y = device_height / image_height
   device_x = image_x * scale_x
   device_y = image_y * scale_y
   ```

**Finding map elements by color:**

`find_colors.py` locates clusters of specific colors in screenshots and returns their center coordinates in image space.

```bash
# Find red markers
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/find_colors.py" /tmp/screenshot.png red

# Find green clusters with custom tolerance
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/find_colors.py" /tmp/screenshot.png green --tolerance 80

# Restrict search to the MapView area (skip toolbar/nav bar)
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/find_colors.py" /tmp/screenshot.png red --bounds 0,120,2960,1848

# Custom RGB color
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/find_colors.py" /tmp/screenshot.png --rgb 51,102,255

# JSON output for programmatic use
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/find_colors.py" /tmp/screenshot.png red --json
```

Available named colors: `red`, `green`, `blue`, `yellow`, `orange`, `white`, `black`, `cyan`, `magenta`. Named colors are approximate — if a named color misses visible elements, use `--rgb R,G,B` to target the exact shade, or increase `--tolerance`. Default tolerance is 70; lower for stricter matching, higher (80-100) for broader matching. Use `--min-size` (default 10) to filter out noise.

## Map Gestures

### Before Any Gesture

1. Run `"$SKILL_DIR/tools/device_info.sh" size` to get screen resolution
2. Take a screenshot (`"$SKILL_DIR/tools/screenshot.sh"`) and read it to identify the map area vs UI overlays (toolbars, FABs, bottom bars)
3. Compute the map center coordinates — target all gestures within the map area only

### Iterative Zoom and Re-identification

- After each zoom gesture, ALWAYS re-screenshot and re-identify the target before the next gesture. Never chain multiple zooms without re-screenshotting.
- Double-tap zoom centers on the tap point — coordinate offset errors compound exponentially with each zoom.
- For precise targeting: zoom to the general area (2–3 steps with re-screenshot between each), then use `find_colors.py` or `ui_dump.sh` for exact coordinates of the shifted target.

### Single-Touch Gestures (reliable)

**Double tap to zoom in:**
```bash
"$SKILL_DIR/tools/input.sh" tap <cx> <cy> && sleep 0.08 && "$SKILL_DIR/tools/input.sh" tap <cx> <cy>
```

**Long press** (e.g. to select a map point, drop a pin):
```bash
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" long_press <cx> <cy> --duration 1000
```

**Pan map:**
```bash
"$SKILL_DIR/tools/input.sh" swipe <cx> <cy> <cx> $((cy-300)) 300   # Pan up
"$SKILL_DIR/tools/input.sh" swipe <cx> <cy> <cx> $((cy+300)) 300   # Pan down
"$SKILL_DIR/tools/input.sh" swipe <cx> <cy> $((cx-300)) <cy> 300    # Pan left
"$SKILL_DIR/tools/input.sh" swipe <cx> <cy> $((cx+300)) <cy> 300    # Pan right
```

> **Note:** There is no single-touch zoom-out gesture. To zoom out, use `pinch_in` (multi-touch) below.

### Multi-Touch Gestures (via uiautomator2)

Multi-touch gestures use `$SKILL_DIR/tools/gesture_helper.py` with a local Python venv.

**Setup prerequisites:**
- A device must be connected — `setup.sh` installs the ATX agent on the device.
- If the venv becomes stale (e.g. after a Python upgrade), `setup.sh` auto-detects and recreates it.
- For multi-device setups, pass `--serial <serial>` (or `-s <serial>`) to `gesture_helper.py`.

**Ensure the venv exists** (idempotent — safe to re-run):
```bash
"$SKILL_DIR/tools/setup.sh"
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

# Multi-device: pass --serial / -s
"$SKILL_DIR/tools/.venv/bin/python3" "$SKILL_DIR/tools/gesture_helper.py" pinch_out <cx> <cy> -s <serial>
```

If `cx`/`cy` are omitted, screen center is used. Adjust `--radius` for gesture magnitude (larger = more zoom/tilt/rotation). Adjust `--steps` for smoothness (higher = smoother but slower).

## Tips

- When `INSTALL_FAILED_UPDATE_INCOMPATIBLE` occurs, uninstall the existing app first.
- Use `"$SKILL_DIR/tools/app.sh" start` with the fully qualified component name to launch exported activities.
- Parse and summarize logcat output — don't dump raw logs without explanation.
- Always take a screenshot before UI interaction to see the current state.
- For map gesture coordinates, compute actual pixel values from screen size and screenshot — don't hardcode.
- When using a specific device, pass `-s <serial>` to ALL tool scripts and raw `adb` commands consistently throughout the session.

## Recommended Permissions

Add these to `~/.claude/settings.json` under `permissions.allow` to avoid repeated prompts for standard operations. Dangerous commands (`adb uninstall`, `adb shell pm clear`, `adb shell rm`) are intentionally excluded and will always prompt. Note: the `logcat.sh`, `gesture_helper.py`, and `find_colors.py` patterns have a trailing space before `*` to enforce their required first argument.

```json
"permissions": {
  "allow": [
    "Bash(*/skills/claude-adb-skill/tools/screenshot.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/logcat.sh *)",
    "Bash(*/skills/claude-adb-skill/tools/ui_dump.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/cleanup.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/setup.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/gesture_helper.py *)",
    "Bash(*/skills/claude-adb-skill/tools/find_colors.py *)",
    "Bash(*/skills/claude-adb-skill/tools/input.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/app.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/device_info.sh*)",
    "Bash(*/skills/claude-adb-skill/tools/file.sh*)",
    "Read(/tmp/*.png)",
    "Read(/tmp/ui_dump.xml)"
  ]
}
```
