#!/usr/bin/env python3
"""
OCR script to read numbers from an image using EasyOCR
Usage: python3 readNumbersOCR.py <image_path>
       python3 readNumbersOCR.py --stdin
"""

import sys
import os

def main():
    # Check if reading from stdin or file
    if '--stdin' in sys.argv:
        read_from_stdin = True
    elif len(sys.argv) == 2 and sys.argv[1] != '--stdin':
        read_from_stdin = False
        image_path = sys.argv[1]
    else:
        print("Usage: python3 readNumbersOCR.py <image_path> OR --stdin", file=sys.stderr)
        sys.exit(1)

    try:
        import easyocr
        from PIL import Image
        import numpy as np
        from io import BytesIO
    except ImportError as e:
        print(f"ERROR: Missing dependency: {e}. Install with: pip3 install easyocr pillow", file=sys.stderr)
        sys.exit(1)

    try:
        if read_from_stdin:
            # Read image data from stdin
            image_data = sys.stdin.buffer.read()
            img = Image.open(BytesIO(image_data))
        else:
            # Read from file path
            if not os.path.exists(image_path):
                print(f"ERROR: Image file not found: {image_path}", file=sys.stderr)
                sys.exit(1)
            img = Image.open(image_path)

        # Convert to RGB if needed (EasyOCR works better with RGB)
        if img.mode != 'RGB':
            img = img.convert('RGB')

        # Convert to numpy array for EasyOCR
        img_array = np.array(img)

        # Initialize reader for English
        reader = easyocr.Reader(['en'], gpu=False, verbose=False)

        # Read text from image with number whitelist
        results = reader.readtext(img_array, allowlist='0123456789')

        # Extract just the numbers
        numbers = ''.join([text for (bbox, text, prob) in results])

        # Remove any spaces
        numbers = numbers.replace(' ', '').strip()

        if numbers:
            print(numbers)
            sys.exit(0)
        else:
            sys.exit(1)

    except Exception as e:
        print(f"ERROR: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
