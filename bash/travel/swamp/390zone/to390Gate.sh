#!/bin/bash
# MOVE TO RIGHT GATE
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

sleep 2

# Open map
tap_openMap
sleep 0.5
# Click top gate zone
adb_tap 1740 780
# Close map
sleep 0.5
tap_closeMap
sleep 3
