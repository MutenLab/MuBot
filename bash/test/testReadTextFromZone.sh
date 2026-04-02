#!/bin/bash
# Test script for readTextFromZone function
# Usage: ./testReadTextFromZone.sh X Y WIDTH HEIGHT [THRESHOLD]
# Example: ./testReadTextFromZone.sh 100 200 300 50 60
# ==================================================

# Source visionUtils to get the readTextFromZone function
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/visionUtils.sh

# Get parameters from command line arguments
X=${1:-0}
Y=${2:-0}
WIDTH=${3:-100}
HEIGHT=${4:-50}
THRESHOLD=${5:-60}  # Default threshold is 60%

# Validate that parameters were provided
if [[ $# -lt 4 ]]; then
    echo "Usage: $0 X Y WIDTH HEIGHT [THRESHOLD]"
    echo "Example: $0 100 200 300 50 60"
    echo ""
    echo "Parameters:"
    echo "  X        - X coordinate of the zone (left edge)"
    echo "  Y        - Y coordinate of the zone (top edge)"
    echo "  WIDTH    - Width of the zone to capture"
    echo "  HEIGHT   - Height of the zone to capture"
    echo "  THRESHOLD - Optional: Threshold percentage for OCR (default: 60)"
    exit 1
fi

echo "Reading text from zone: X=$X, Y=$Y, WIDTH=$WIDTH, HEIGHT=$HEIGHT, THRESHOLD=$THRESHOLD"
echo "---"

# Call the function to read text from the zone
text=$(readTextFromZone "$X" "$Y" "$WIDTH" "$HEIGHT" "$THRESHOLD")
exit_code=$?

# Display results
if [[ $exit_code -eq 0 && -n "$text" ]]; then
    echo "Detected text: $text"
    exit 0
else
    echo "No text detected in the specified zone"
    exit 1
fi
