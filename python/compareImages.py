#!/usr/bin/env python3
"""
Image comparison script using SSIM (Structural Similarity Index)
Usage: python3 compareImages.py <reference_image_path> --stdin
       python3 compareImages.py <reference_image_path> <test_image_path>
"""

import sys
import os

def main():
    # Check arguments
    if len(sys.argv) < 2:
        print("Usage: python3 compareImages.py <reference_image_path> [--stdin | <test_image_path>]", file=sys.stderr)
        sys.exit(1)

    reference_path = sys.argv[1]

    # Check if reading test image from stdin or file
    if len(sys.argv) == 3 and sys.argv[2] == '--stdin':
        read_from_stdin = True
    elif len(sys.argv) == 3:
        read_from_stdin = False
        test_path = sys.argv[2]
    else:
        print("Usage: python3 compareImages.py <reference_image_path> [--stdin | <test_image_path>]", file=sys.stderr)
        sys.exit(1)

    # Validate reference image exists
    if not os.path.exists(reference_path):
        print(f"ERROR: Reference image not found: {reference_path}", file=sys.stderr)
        sys.exit(1)

    try:
        from PIL import Image
        import numpy as np
        from skimage.metrics import structural_similarity as ssim
        from io import BytesIO
    except ImportError as e:
        print(f"ERROR: Missing dependency: {e}. Install with: pip3 install pillow scikit-image", file=sys.stderr)
        sys.exit(1)

    try:
        # Load reference image
        ref_img = Image.open(reference_path)

        # Load test image
        if read_from_stdin:
            image_data = sys.stdin.buffer.read()
            test_img = Image.open(BytesIO(image_data))
        else:
            if not os.path.exists(test_path):
                print(f"ERROR: Test image not found: {test_path}", file=sys.stderr)
                sys.exit(1)
            test_img = Image.open(test_path)

        # Convert to grayscale for comparison
        ref_gray = ref_img.convert('L')
        test_gray = test_img.convert('L')

        # Resize test image to match reference if needed
        if test_gray.size != ref_gray.size:
            test_gray = test_gray.resize(ref_gray.size, Image.Resampling.LANCZOS)

        # Convert to numpy arrays
        ref_array = np.array(ref_gray)
        test_array = np.array(test_gray)

        # Calculate SSIM (Structural Similarity Index)
        # Returns a value between -1 and 1, where 1 means identical
        similarity_index = ssim(ref_array, test_array)

        # Convert to percentage (0-100)
        similarity_percent = (similarity_index + 1) / 2 * 100

        # Output similarity percentage
        print(f"{similarity_percent:.2f}")
        sys.exit(0)

    except Exception as e:
        print(f"ERROR: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
