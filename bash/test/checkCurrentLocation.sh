#!/bin/bash
# Test script to check current map location
# Usage: ./checkCurrentLocation.sh
# ==================================================

source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/visionUtils.sh

echo "Checking current location..."
location=$(getLocation)
echo "Location code: $location"
