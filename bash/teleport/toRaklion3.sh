#!/bin/bash
# TELEPORT TO RAKLION 3
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

# Open map
sleep 0.5
tap_openMap
# Map swipe to scroll
sleep 0.5
adb_swipe 400 900 400 600 500
# Click raklion title
sleep 2
adb_tap 800 800
# Click raklion 3 subtitle
sleep 1
adb_tap 820 820
