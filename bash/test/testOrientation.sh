#!/bin/bash
# TEST SCREEN ORIENTATION DETECTION
# Detects if emulator is in portrait or landscape mode
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

echo "==================================================="
echo "SCREEN ORIENTATION DETECTION TEST"
echo "==================================================="
echo ""
echo "Capturing screen to detect orientation..."
echo ""

# Capture screenshot and get dimensions using ImageMagick
dimensions=$(adb_screencap | magick png:- -format "%w %h" info:)

# Extract width and height
width=$(echo $dimensions | cut -d' ' -f1)
height=$(echo $dimensions | cut -d' ' -f2)

echo "Screen dimensions detected:"
echo "  Width:  $width"
echo "  Height: $height"
echo ""

# Determine orientation
if [ $width -gt $height ]; then
    orientation="LANDSCAPE"
    game_status="RUNNING"
else
    orientation="PORTRAIT"
    game_status="CLOSED"
fi

echo "==================================================="
echo "RESULT:"
echo "  Orientation: $orientation"
echo "  Game status: $game_status"
echo "==================================================="
echo ""

if [ "$orientation" = "LANDSCAPE" ]; then
    echo "✓ Screen is in landscape mode (width > height)"
    echo "  This typically means the game is running."
    exit 0
else
    echo "✓ Screen is in portrait mode (height > width)"
    echo "  This typically means you're on the home screen."
    exit 1
fi
