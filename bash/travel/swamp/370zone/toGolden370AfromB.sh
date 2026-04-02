#!/bin/bash
# MOVE TO GOLDEN 370A FROM B
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

# TO GOLDEN 370A
# ====================
# Open map
tap_openMap
sleep 0.5
# Click golden zone
adb_tap 1720 415
sleep 0.5
# Close map
tap_closeMap
sleep 6.5
# Teleport with skill to save time
#adb_text 4
