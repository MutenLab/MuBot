#!/bin/bash
# MOVE TO GOLDEN 350 FROM RIGHT GATE
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

sleep 2
# TO GOLDEN 400
# ====================
# Open map
tap_openMap
sleep 0.5
# Click golden zone
adb_tap 1740 1120
sleep 0.5
# Close map
tap_closeMap
sleep 9
