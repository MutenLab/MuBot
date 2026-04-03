#!/bin/bash
# MOVE TO GOLDEN 360 FROM GOLDEN 350
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

# TO RIGHT GOLDEN 360
# ====================
# Open map
tap_openMap
sleep 0.5
# Click golden zone
adb_tap 2060 640
sleep 0.5
# Close map
tap_closeMap
sleep 11
# Teleport with skill to save time
adb_text 4
