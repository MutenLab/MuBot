#!/bin/bash
# TELEPORT TO SWAMP OF PEACE
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

# Open map
sleep 0.5
tap_openMap
# Map swipe to scroll
sleep 0.5
adb_swipe 400 615 400 260 420
# Click title
sleep 2
adb_tap 400 670
sleep 3
