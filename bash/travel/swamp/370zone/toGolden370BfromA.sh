#!/bin/bash
# MOVE TO GOLDEN 350 FROM GOLDEN 360
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

# TO RIGHT GOLDEN 360
# ====================
# Open map
tap_openMap
sleep 0.5
# Click golden zone
adb_tap 1760 340
sleep 0.5
# Close map
tap_closeMap
sleep 7
# Teleport with skill to save time
#adb_text 4
