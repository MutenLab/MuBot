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
adb_swipe 400 900 400 500 500
# Click corrupted lands title
sleep 2
adb_tap 800 880
sleep 3
