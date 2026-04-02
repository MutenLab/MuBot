#!/bin/bash
# TELEPORT TO ENDLESS ABYSS
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

# Open map
sleep 1
tap_openMap
# Map swipe to scroll
sleep 1
adb_swipe 400 900 400 100 200
sleep 2
# Click title
adb_tap 820 560
