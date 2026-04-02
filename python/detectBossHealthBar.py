#!/usr/bin/env python3
"""
Detect if boss health bar is visible at the top of the screen.
The health bar appears when a boss is targeted/being attacked.

Usage:
    python3 detectBossHealthBar.py --stdin
    python3 detectBossHealthBar.py <screenshot_path>

Output:
    "alive" - Boss health bar is visible (red pixels detected)
    "dead" - No boss health bar visible
"""

import sys
import os
from io import BytesIO

# Boss health bar region (top center of screen)
# Based on 1920x1080 screen resolution (BlueStacks)
HEALTH_BAR_REGION = {
    "x": 860,
    "y": 48,
    "width": 280,
    "height": 14
}

# Red color thresholds for health bar detection
# Health bar has RGB around (200, 50, 50)
MIN_RED = 180
MAX_GREEN = 80
MAX_BLUE = 80
MIN_RED_PIXELS = 20  # Minimum red pixels to consider bar visible


def check_health_bar(img):
    """Check if boss health bar is visible by detecting red pixels."""
    x = HEALTH_BAR_REGION["x"]
    y = HEALTH_BAR_REGION["y"]
    width = HEALTH_BAR_REGION["width"]
    height = HEALTH_BAR_REGION["height"]

    red_pixel_count = 0

    for px in range(x, x + width):
        for py in range(y, y + height):
            if 0 <= px < img.width and 0 <= py < img.height:
                pixel = img.getpixel((px, py))
                if len(pixel) >= 3:
                    r, g, b = pixel[0], pixel[1], pixel[2]
                    # Check if pixel is red (health bar color)
                    if r >= MIN_RED and g <= MAX_GREEN and b <= MAX_BLUE:
                        red_pixel_count += 1

    return red_pixel_count >= MIN_RED_PIXELS


def main():
    read_from_stdin = '--stdin' in sys.argv
    image_path = None

    for arg in sys.argv[1:]:
        if not arg.startswith('-'):
            image_path = arg
            break

    if not read_from_stdin and not image_path:
        print("Usage: python3 detectBossHealthBar.py [--stdin | <screenshot_path>]", file=sys.stderr)
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
            if not os.path.exists(image_path):
                print(f"ERROR: Image not found: {image_path}", file=sys.stderr)
                sys.exit(1)
            img = Image.open(image_path)

        if img.mode != 'RGB':
            img = img.convert('RGB')

        if check_health_bar(img):
            print("alive")
        else:
            print("dead")

        sys.exit(0)

    except Exception as e:
        print(f"ERROR: {str(e)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
