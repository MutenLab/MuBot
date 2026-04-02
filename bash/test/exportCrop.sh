#!/bin/bash

# Script to export a cropped screenshot to Desktop
# Usage: ./exportCrop.sh X Y WIDTH HEIGHT
# Example: ./exportCrop.sh 100 200 300 50

# Source visionUtils to get the exportCroppedImage function
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/visionUtils.sh

# Get parameters from command line arguments
X=${1:-0}
Y=${2:-0}
WIDTH=${3:-100}
HEIGHT=${4:-50}

# Validate that parameters were provided
if [[ $# -lt 4 ]]; then
    echo "Usage: $0 X Y WIDTH HEIGHT"
    echo "Example: $0 100 200 300 50"
    echo ""
    echo "Exports a cropped screenshot to ~/Desktop/exported_crop_X_Y.png"
    exit 1
fi

# Call the function to export cropped image
exportCroppedImage "$X" "$Y" "$WIDTH" "$HEIGHT"

# Exit with function's return code
exit $?
