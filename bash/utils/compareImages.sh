#!/bin/bash

# Script to compare a screen region with a reference image
# Usage: ./compareScreen.sh X Y WIDTH HEIGHT REFERENCE_IMAGE_PATH
# Example: ./compareScreen.sh 100 200 300 50 /path/to/reference.png

# Source visionUtils to get the compareScreenWithImage function
source $PROJECT_DIR/bash/utils/visionUtils.sh

# Get parameters from command line arguments
X=${1:-0}
Y=${2:-0}
WIDTH=${3:-100}
HEIGHT=${4:-50}
REFERENCE_IMAGE=${5:-""}

# Validate that all parameters were provided
if [[ $# -lt 5 ]]; then
    echo "Usage: $0 X Y WIDTH HEIGHT REFERENCE_IMAGE_PATH"
    echo "Example: $0 100 200 300 50 /path/to/reference.png"
    exit 1
fi

# Call the function to compare screen region with reference image
result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$REFERENCE_IMAGE")

# Output result
echo "$result"

# Exit with appropriate code
if [[ "$result" == "similar" ]]; then
    exit 0
else
    exit 1
fi
