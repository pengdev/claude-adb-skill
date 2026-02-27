#!/usr/bin/env python3
"""Multi-touch gesture helper for Android devices via uiautomator2.

Usage:
    .venv/bin/python3 gesture_helper.py <gesture> [cx cy] [--radius R] [--steps N]

Gestures:
    pinch_out   — two fingers spread outward (zoom in)
    pinch_in    — two fingers move inward (zoom out)
    tilt_up     — two fingers drag up together (pitch map forward)
    tilt_down   — two fingers drag down together (pitch map back)
    rotate_cw   — two fingers rotate clockwise
    rotate_ccw  — two fingers rotate counter-clockwise

If cx/cy are omitted, screen center is used.

Setup: run setup.sh once to create the venv.
"""

import argparse
import sys

import uiautomator2 as u2


def connect():
    d = u2.connect()
    info = d.info
    w, h = info["displayWidth"], info["displayHeight"]
    return d, w, h


def pinch_out(d, cx, cy, radius, steps):
    """Two fingers spread outward from near center."""
    offset = 30  # start close together
    d().gesture(
        (cx - offset, cy - offset),
        (cx + offset, cy + offset),
        (cx - radius, cy - radius),
        (cx + radius, cy + radius),
        steps=steps,
    )


def pinch_in(d, cx, cy, radius, steps):
    """Two fingers move inward toward center."""
    offset = 30
    d().gesture(
        (cx - radius, cy - radius),
        (cx + radius, cy + radius),
        (cx - offset, cy - offset),
        (cx + offset, cy + offset),
        steps=steps,
    )


def tilt_up(d, cx, cy, radius, steps):
    """Two fingers drag upward together (map tilt forward)."""
    dist = radius
    d().gesture(
        (cx - 100, cy + dist // 2),
        (cx + 100, cy + dist // 2),
        (cx - 100, cy - dist),
        (cx + 100, cy - dist),
        steps=steps,
    )


def tilt_down(d, cx, cy, radius, steps):
    """Two fingers drag downward together (map tilt back)."""
    dist = radius
    d().gesture(
        (cx - 100, cy - dist // 2),
        (cx + 100, cy - dist // 2),
        (cx - 100, cy + dist),
        (cx + 100, cy + dist),
        steps=steps,
    )


def rotate_cw(d, cx, cy, radius, steps):
    """Two fingers rotate clockwise ~90 degrees."""
    r = radius
    d().gesture(
        (cx, cy - r),   # finger 1 starts top
        (cx, cy + r),   # finger 2 starts bottom
        (cx + r, cy),   # finger 1 ends right
        (cx - r, cy),   # finger 2 ends left
        steps=steps,
    )


def rotate_ccw(d, cx, cy, radius, steps):
    """Two fingers rotate counter-clockwise ~90 degrees."""
    r = radius
    d().gesture(
        (cx, cy - r),   # finger 1 starts top
        (cx, cy + r),   # finger 2 starts bottom
        (cx - r, cy),   # finger 1 ends left
        (cx + r, cy),   # finger 2 ends right
        steps=steps,
    )


GESTURES = {
    "pinch_out": pinch_out,
    "pinch_in": pinch_in,
    "tilt_up": tilt_up,
    "tilt_down": tilt_down,
    "rotate_cw": rotate_cw,
    "rotate_ccw": rotate_ccw,
}


def main():
    parser = argparse.ArgumentParser(description="Multi-touch gesture helper")
    parser.add_argument("gesture", choices=GESTURES.keys(), help="Gesture to perform")
    parser.add_argument("cx", nargs="?", type=int, default=None, help="Center X (default: screen center)")
    parser.add_argument("cy", nargs="?", type=int, default=None, help="Center Y (default: screen center)")
    parser.add_argument("--radius", type=int, default=200, help="Gesture radius in pixels (default: 200)")
    parser.add_argument("--steps", type=int, default=30, help="Animation steps (default: 30)")
    args = parser.parse_args()

    d, w, h = connect()
    cx = args.cx if args.cx is not None else w // 2
    cy = args.cy if args.cy is not None else h // 2

    print(f"Performing {args.gesture} at ({cx},{cy}) radius={args.radius} steps={args.steps}")
    import time
    for attempt in range(3):
        try:
            GESTURES[args.gesture](d, cx, cy, args.radius, args.steps)
            print("Done.")
            break
        except Exception as e:
            if attempt < 2:
                print(f"  Retrying ({e})...")
                time.sleep(2)
                d = u2.connect()
            else:
                raise


if __name__ == "__main__":
    main()
