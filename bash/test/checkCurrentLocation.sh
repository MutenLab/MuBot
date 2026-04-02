#!/bin/bash
# Test script to check current map location
# Usage: ./checkCurrentLocation.sh
# ==================================================

source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/visionUtils.sh

echo "Checking current location..."
location=$(getLocation)
echo "Location code: $location"
