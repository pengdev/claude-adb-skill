#!/usr/bin/env python3
"""Find colored elements in Android device screenshots.

Scans a screenshot for pixel clusters matching a named color or custom RGB value.
Returns center coordinates in image space — use the coordinate scaling workflow
in SKILL.md to convert to device coordinates.

Usage:
    .venv/bin/python3 find_colors.py <image_path> [color_name] [options]

Colors:
    red, green, blue, yellow, orange, white, black, cyan, magenta

Options:
    --rgb R,G,B         Custom RGB target (overrides color name)
    --tolerance N       Color distance threshold (default: 70)
    --bounds L,T,R,B    Restrict search to sub-region (e.g., MapView area)
    --min-size N        Min pixel cluster size to report (default: 10)
    --json              Output JSON instead of human-readable

Setup: run setup.sh once to create the venv (Pillow is a transitive dep of
uiautomator2).
"""

import argparse
import collections
import json
import math
import sys

try:
    from PIL import Image
except ImportError:
    print(
        "Error: Pillow is not installed.\n"
        "Run the setup script first:\n"
        "  $SKILL_DIR/tools/setup.sh\n"
        "Then invoke this script via:\n"
        "  $SKILL_DIR/tools/.venv/bin/python3 find_colors.py ...",
        file=sys.stderr,
    )
    sys.exit(1)

NAMED_COLORS = {
    "red": (255, 0, 0),
    "green": (0, 210, 0),
    "blue": (0, 0, 255),
    "yellow": (255, 255, 0),
    "orange": (255, 165, 0),
    "white": (255, 255, 255),
    "black": (0, 0, 0),
    "cyan": (0, 255, 255),
    "magenta": (255, 0, 255),
}


def color_distance(c1, c2):
    """Euclidean distance between two RGB tuples."""
    return math.sqrt(sum((a - b) ** 2 for a, b in zip(c1, c2)))


def find_matching_pixels(img, target_rgb, tolerance, bounds):
    """Return a set of (x, y) pixel positions matching target_rgb within tolerance."""
    w, h = img.size
    left, top, right, bottom = bounds if bounds else (0, 0, w, h)
    left = max(0, left)
    top = max(0, top)
    right = min(w, right)
    bottom = min(h, bottom)

    pixels = img.load()
    matching = set()
    for y in range(top, bottom):
        for x in range(left, right):
            px = pixels[x, y]
            # Handle RGBA by taking first 3 channels
            rgb = px[:3] if len(px) >= 3 else px
            if color_distance(rgb, target_rgb) <= tolerance:
                matching.add((x, y))
    return matching


def cluster_pixels(matching):
    """BFS-based connected-component clustering of pixel positions."""
    visited = set()
    clusters = []

    for start in matching:
        if start in visited:
            continue
        cluster = []
        queue = collections.deque([start])
        visited.add(start)
        while queue:
            x, y = queue.popleft()
            cluster.append((x, y))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    if dx == 0 and dy == 0:
                        continue
                    nb = (x + dx, y + dy)
                    if nb in matching and nb not in visited:
                        visited.add(nb)
                        queue.append(nb)
        clusters.append(cluster)
    return clusters


def cluster_info(cluster):
    """Compute center, bounding box, and pixel count for a cluster."""
    xs = [p[0] for p in cluster]
    ys = [p[1] for p in cluster]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    cx = (min_x + max_x) // 2
    cy = (min_y + max_y) // 2
    return {
        "center": (cx, cy),
        "bbox": (min_x, min_y, max_x, max_y),
        "width": max_x - min_x + 1,
        "height": max_y - min_y + 1,
        "pixels": len(cluster),
    }


def main():
    parser = argparse.ArgumentParser(
        description="Find colored elements in Android device screenshots"
    )
    parser.add_argument("image", help="Path to screenshot PNG")
    parser.add_argument(
        "color",
        nargs="?",
        default=None,
        choices=list(NAMED_COLORS.keys()),
        help="Named color to search for",
    )
    parser.add_argument(
        "--rgb",
        type=str,
        default=None,
        help="Custom RGB target as R,G,B (e.g., 255,0,0)",
    )
    parser.add_argument(
        "--tolerance",
        type=int,
        default=70,
        help="Color distance threshold (default: 70)",
    )
    parser.add_argument(
        "--bounds",
        type=str,
        default=None,
        help="Restrict search to L,T,R,B sub-region (e.g., 0,120,2960,1848)",
    )
    parser.add_argument(
        "--min-size",
        type=int,
        default=10,
        help="Min pixel cluster size to report (default: 10)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output JSON instead of human-readable",
    )
    args = parser.parse_args()

    if args.rgb:
        try:
            parts = [int(x.strip()) for x in args.rgb.split(",")]
            if len(parts) != 3:
                raise ValueError
            target_rgb = tuple(parts)
        except ValueError:
            print("Error: --rgb must be R,G,B (e.g., 255,0,0)", file=sys.stderr)
            sys.exit(1)
        color_label = f"rgb({args.rgb})"
    elif args.color:
        target_rgb = NAMED_COLORS[args.color]
        color_label = args.color
    else:
        print("Error: specify a color name or --rgb R,G,B", file=sys.stderr)
        sys.exit(1)

    bounds = None
    if args.bounds:
        try:
            parts = [int(x.strip()) for x in args.bounds.split(",")]
            if len(parts) != 4:
                raise ValueError
            bounds = tuple(parts)
        except ValueError:
            print("Error: --bounds must be L,T,R,B (e.g., 0,120,2960,1848)", file=sys.stderr)
            sys.exit(1)

    try:
        img = Image.open(args.image).convert("RGB")
    except FileNotFoundError:
        print(f"Error: file not found: {args.image}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error opening image: {e}", file=sys.stderr)
        sys.exit(1)

    w, h = img.size
    matching = find_matching_pixels(img, target_rgb, args.tolerance, bounds)
    clusters = cluster_pixels(matching)

    # Filter by min-size and sort by pixel count descending
    results = []
    for cl in clusters:
        info = cluster_info(cl)
        if info["pixels"] >= args.min_size:
            results.append(info)
    results.sort(key=lambda r: r["pixels"], reverse=True)

    if args.json:
        output = {
            "image_size": {"width": w, "height": h},
            "color": color_label,
            "tolerance": args.tolerance,
            "bounds": bounds,
            "regions": [
                {
                    "center": {"x": r["center"][0], "y": r["center"][1]},
                    "bbox": {
                        "left": r["bbox"][0],
                        "top": r["bbox"][1],
                        "right": r["bbox"][2],
                        "bottom": r["bbox"][3],
                    },
                    "width": r["width"],
                    "height": r["height"],
                    "pixels": r["pixels"],
                }
                for r in results
            ],
        }
        print(json.dumps(output, indent=2))
    else:
        print(f"Image size: {w}x{h}")
        if not results:
            print(f"No regions matching '{color_label}' (tolerance={args.tolerance})")
        else:
            print(
                f"Found {len(results)} region(s) matching '{color_label}' "
                f"(tolerance={args.tolerance}):"
            )
            for i, r in enumerate(results, 1):
                cx, cy = r["center"]
                print(
                    f"  {i}. center=({cx}, {cy}) "
                    f"size={r['width']}x{r['height']} "
                    f"pixels={r['pixels']}"
                )


if __name__ == "__main__":
    main()
