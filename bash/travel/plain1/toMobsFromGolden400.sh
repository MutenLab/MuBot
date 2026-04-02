#!/bin/bash
# MOVE TO GOLDEN 350 FROM RIGHT GATE
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

sleep 2
# TO GOLDEN 400
# ====================
# Open map
tap_openMap
sleep 0.5
# Click mob zone
adb_tap 1680 915
sleep 0.5
# Close map
tap_closeMap
sleep 8
