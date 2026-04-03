#!/bin/bash
# MOVE TO GOLDEN 350 FROM RIGHT GATE
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

# TO TOP GATE
# ==============
$PROJECT_DIR/bash/travel/swamp/380zone/to380Gate.sh

# TO BOSS
# ====================
# Open map
tap_openMap
sleep 0.5
# Click boss zone
adb_tap 1279 681
sleep 0.2
# Close map
tap_closeMap
sleep 18
