#!/usr/bin/env python3
"""
Debug script to show RGB values at each boss location.
Helps calibrate alive/dead color detection thresholds.
Usage:
    python3 debugBossColors.py <screenshot_path>
    python3 debugBossColors.py --stdin
"""

import sys
import os
from io import BytesIO

# Boss coordinates (must match sanctuary2_bosses.sh)
BOSS_COORDS = {
    1: (1950, 820),
    2: (1915, 660),
    3: (1760, 620),
    4: (1720, 470),
    5: (1555, 425),
    6: (1545, 575),
    7: (1820, 840),
    8: (1810, 965),
    9: (1650, 930),
    10: (1615, 780),
    11: (1455, 730),
    12: (1415, 580),
}

def get_average_color(img, x, y, sample_size=5):
    """Get average RGB color in a small area around the coordinate."""
    r_total, g_total, b_total = 0, 0, 0
    count = 0

    half = sample_size // 2
    for dx in range(-half, half + 1):
        for dy in range(-half, half + 1):
            px = x + dx
            py = y + dy
            if 0 <= px < img.width and 0 <= py < img.height:
                pixel = img.getpixel((px, py))
                if len(pixel) >= 3:
                    r_total += pixel[0]
                    g_total += pixel[1]
                    b_total += pixel[2]
                    count += 1

    if count == 0:
        return (0, 0, 0)

    return (r_total // count, g_total // count, b_total // count)

def main():
    read_from_stdin = '--stdin' in sys.argv
    image_path = None

    for arg in sys.argv[1:]:
        if not arg.startswith('-'):
            image_path = arg
            break

    if not read_from_stdin and not image_path:
        print("Usage: python3 debugBossColors.py [--stdin | <screenshot_path>]", file=sys.stderr)
        sys.exit(1)

    try:
        from PIL import Image
    except ImportError:
        print("ERROR: Missing PIL. Install with: pip3 install pillow", file=sys.stderr)
        sys.exit(1)

    try:
        if read_from_stdin:
            image_data = sys.stdin.buffer.read()
            img = Image.open(BytesIO(image_data))
        else:
            img = Image.open(image_path)

        if img.mode != 'RGB':
            img = img.convert('RGB')

        print(f"Image size: {img.width}x{img.height}")
        print("-" * 60)
        print(f"{'Boss':<8} {'Coords':<14} {'R':<5} {'G':<5} {'B':<5} {'Status'}")
        print("-" * 60)

        for boss_num in sorted(BOSS_COORDS.keys()):
            x, y = BOSS_COORDS[boss_num]
            r, g, b = get_average_color(img, x, y)

            # Determine status using same logic as detectBossStatus.py
            max_c = max(r, g, b)
            min_c = min(r, g, b)
            saturation = (max_c - min_c) / max_c if max_c > 0 else 0
            is_red_dominant = r > g and r > b
            has_saturation = saturation > 0.3
            is_bright_enough = r > 120
            rg_ratio = r / g if g > 0 else r
            is_alive = is_red_dominant and has_saturation and is_bright_enough and rg_ratio > 1.3

            status = "ALIVE" if is_alive else "DEAD"
            print(f"BOSS_{boss_num:<3} ({x:>4},{y:>4})   {r:<5} {g:<5} {b:<5} {status}")

        print("-" * 60)

    except Exception as e:
        print(f"ERROR: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
