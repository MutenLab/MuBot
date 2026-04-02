#!/bin/bash
# MOVE TO RIGHT GATE
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

sleep 2.5
# Open map
tap_openMap
sleep 0.5
# Click right gate zone
adb_tap 1745 720
# Close map
sleep 0.5
tap_closeMap
sleep 6
# Arrive to right dragon head gate
adb_tap 1729 429
sleep 1
