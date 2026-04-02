#!/bin/bash
# TELEPORT TO DIVINE
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

# Open map
sleep 1
tap_openMap
# Map swipe to scroll
sleep 1
adb_swipe 400 690 400 0 200
sleep 2
adb_swipe 400 670 400 750 300
# Click divine title
sleep 2.5
adb_tap 400 230
