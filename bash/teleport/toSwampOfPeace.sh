#!/bin/bash
# TELEPORT TO SWAMP OF PEACE
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

# Open map
sleep 0.5
tap_openMap
# Map swipe to scroll
sleep 0.5
adb_swipe 400 900 400 600 500
# Click swamp of peace title
sleep 2
adb_tap 800 900
sleep 3
