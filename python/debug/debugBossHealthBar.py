#!/usr/bin/env python3
"""
Debug script to find the boss health bar region.
"""

import sys
from PIL import Image

def main():
    image_path = sys.argv[1] if len(sys.argv) > 1 else None

    if not image_path:
        print("Usage: python3 debugBossHealthBar.py <screenshot_path>")
        sys.exit(1)

    img = Image.open(image_path)
    if img.mode != 'RGB':
        img = img.convert('RGB')

    print(f"Image size: {img.width}x{img.height}")

    # Search for TRUE red pixels (R much higher than G and B)
    # Health bar should be bright red
    print("\nSearching for TRUE red pixels (R > 180, G < 80, B < 80)...")
    true_red = []
    for y in range(0, 100):
        for x in range(0, img.width):
            pixel = img.getpixel((x, y))
            r, g, b = pixel[0], pixel[1], pixel[2]
            if r > 180 and g < 80 and b < 80:
                true_red.append((x, y, r, g, b))

    print(f"Found {len(true_red)} true red pixels")
    if true_red:
        min_x = min(p[0] for p in true_red)
        max_x = max(p[0] for p in true_red)
        min_y = min(p[1] for p in true_red)
        max_y = max(p[1] for p in true_red)
        print(f"Bounding box: x={min_x}-{max_x}, y={min_y}-{max_y}")
        for p in true_red[:20]:
            print(f"  ({p[0]}, {p[1]}): R={p[2]}, G={p[3]}, B={p[4]}")

    # Search for dark red pixels
    print("\nSearching for dark red pixels (R > 100, R > G*2, R > B*2)...")
    dark_red = []
    for y in range(0, 100):
        for x in range(0, img.width):
            pixel = img.getpixel((x, y))
            r, g, b = pixel[0], pixel[1], pixel[2]
            if r > 100 and r > g * 2 and r > b * 2:
                dark_red.append((x, y, r, g, b))

    print(f"Found {len(dark_red)} dark red pixels")
    if dark_red:
        min_x = min(p[0] for p in dark_red)
        max_x = max(p[0] for p in dark_red)
        min_y = min(p[1] for p in dark_red)
        max_y = max(p[1] for p in dark_red)
        print(f"Bounding box: x={min_x}-{max_x}, y={min_y}-{max_y}")
        for p in dark_red[:20]:
            print(f"  ({p[0]}, {p[1]}): R={p[2]}, G={p[3]}, B={p[4]}")

if __name__ == "__main__":
    main()
