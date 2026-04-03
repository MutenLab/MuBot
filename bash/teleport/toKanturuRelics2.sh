#!/bin/bash
# TELEPORT TO RAKLION 3
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

# Open map
sleep 0.5
tap_openMap
# Map swipe to scroll
sleep 0.5
adb_swipe 400 700 400 550 400
# Click raklion title
sleep 2
adb_tap 400 715
# Click raklion 3 subtitle
sleep 1
adb_tap 400 715
