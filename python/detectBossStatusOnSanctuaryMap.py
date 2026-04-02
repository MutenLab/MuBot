#!/usr/bin/env python3
"""
Boss status detection on Sanctuary 2 map - detects if bosses are alive (red/orange) or dead (brown)
Usage:
    python3 detectBossStatusOnSanctuaryMap.py --stdin
    python3 detectBossStatusOnSanctuaryMap.py <screenshot_path>
    python3 detectBossStatusOnSanctuaryMap.py <screenshot_path> --boss 1  # Check specific boss
Output:
    Without --boss: "1:alive,2:dead,3:alive,..." (all bosses)
    With --boss N: "alive" or "dead" (single boss)
"""

import sys
import os
from io import BytesIO

# Boss coordinates (must match sanctuary2_bosses.sh)
BOSS_COORDS = {
    1: (1321, 673),
    2: (1299, 536),
    3: (1162, 514),
    4: (1141, 376),
    5: (1004, 353),
    6: (1004, 460),
    7: (1220, 677),
    8: (1214, 778),
    9: (1076, 760),
    10: (1056, 620),
    11: (917, 600),
    12: (898, 462),
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

def is_alive(r, g, b):
    """
    Determine if boss is alive based on color.
    Alive: red/orange skull (high red, medium-low green, low blue)
    Dead: brown/gray skull (lower saturation, more muted colors)
    """
    # Calculate color properties
    max_c = max(r, g, b)
    min_c = min(r, g, b)
    saturation = (max_c - min_c) / max_c if max_c > 0 else 0

    # Red/orange detection:
    # - Red should be the dominant channel
    # - Should have decent saturation (not too gray)
    # - Red value should be reasonably high
    is_red_dominant = r > g and r > b
    has_saturation = saturation > 0.3
    is_bright_enough = r > 120

    # Additional check: red-to-green ratio for orange/red vs brown
    rg_ratio = r / g if g > 0 else r

    return is_red_dominant and has_saturation and is_bright_enough and rg_ratio > 1.3

def check_boss_status(img, boss_num):
    """Check if a specific boss is alive or dead."""
    if boss_num not in BOSS_COORDS:
        return "unknown"

    x, y = BOSS_COORDS[boss_num]
    r, g, b = get_average_color(img, x, y)

    return "alive" if is_alive(r, g, b) else "dead"

def main():
    # Parse arguments
    args = sys.argv[1:]
    read_from_stdin = False
    image_path = None
    specific_boss = None

    i = 0
    while i < len(args):
        if args[i] == '--stdin':
            read_from_stdin = True
        elif args[i] == '--boss' and i + 1 < len(args):
            specific_boss = int(args[i + 1])
            i += 1
        elif not args[i].startswith('-'):
            image_path = args[i]
        i += 1

    if not read_from_stdin and not image_path:
        print("Usage: python3 detectBossStatus.py [--stdin | <screenshot_path>] [--boss N]", file=sys.stderr)
        sys.exit(1)

    try:
        from PIL import Image
    except ImportError:
        print("ERROR: Missing PIL. Install with: pip3 install pillow", file=sys.stderr)
        sys.exit(1)

    try:
        # Load image
        if read_from_stdin:
            image_data = sys.stdin.buffer.read()
            img = Image.open(BytesIO(image_data))
        else:
            if not os.path.exists(image_path):
                print(f"ERROR: Image not found: {image_path}", file=sys.stderr)
                sys.exit(1)
            img = Image.open(image_path)

        # Convert to RGB if needed
        if img.mode != 'RGB':
            img = img.convert('RGB')

        # Check specific boss or all bosses
        if specific_boss is not None:
            status = check_boss_status(img, specific_boss)
            print(status)
        else:
            results = []
            for boss_num in sorted(BOSS_COORDS.keys()):
                status = check_boss_status(img, boss_num)
                results.append(f"{boss_num}:{status}")
            print(",".join(results))

        sys.exit(0)

    except Exception as e:
        print(f"ERROR: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
