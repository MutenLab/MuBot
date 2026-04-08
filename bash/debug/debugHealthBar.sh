#!/bin/bash
# Debug script to save health bar crop to Desktop for inspection
# Usage: ./debugHealthBar.sh
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

# Health bar region coordinates
X=860
Y=48
WIDTH=280
HEIGHT=14

OUTPUT_FILE="$HOME/Desktop/health_bar_crop.png"

echo "Capturing health bar region..."
echo "Coordinates: X=$X Y=$Y Width=$WIDTH Height=$HEIGHT"
echo "---"

# Capture and save the cropped health bar
adb_screencap | \
    magick png:- -crop ${WIDTH}x${HEIGHT}+${X}+${Y} \
    -scale 1000% \
    "$OUTPUT_FILE"

if [ -f "$OUTPUT_FILE" ]; then
    echo "✓ Health bar crop saved to: $OUTPUT_FILE"
    echo "(Scaled 10x for easier inspection)"

    # Also show color statistics
    echo ""
    echo "Color analysis:"
    magick "$OUTPUT_FILE" -scale 10% -format "Average color: RGB(%[fx:mean.r*255],%[fx:mean.g*255],%[fx:mean.b*255])" info:
    echo ""

    exit 0
else
    echo "✗ Failed to save crop"
    exit 1
fi
