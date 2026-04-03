#!/bin/bash

# Script to read numbers from a specific screen zone
# Usage: ./readNumbers.sh X Y WIDTH HEIGHT [THRESHOLD]
# Example: ./readNumbers.sh 100 200 300 50 60

# Source visionUtils to get the readNumbersFromZone function
source $PROJECT_DIR/bash/utils/visionUtils.sh

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
    exit 1
fi

# Call the function to read numbers from the zone
numbers=$(readNumbersFromZone "$X" "$Y" "$WIDTH" "$HEIGHT" "$THRESHOLD")

# Check if numbers were detected
if [[ $? -eq 0 && -n "$numbers" ]]; then
    echo "$numbers"
    exit 0
else
    exit 1
fi
