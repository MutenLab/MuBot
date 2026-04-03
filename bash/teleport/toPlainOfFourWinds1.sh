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
adb_swipe 400 900 400 400 500
# Click swamp of peace title
sleep 2.5
adb_tap 800 605
sleep 1
adb_tap 800 560
sleep 3
