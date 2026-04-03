#!/bin/bash
# MOVE TO GOLDEN 350 FROM RIGHT GATE
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

# TO RIGHT GATE
# ==============
$PROJECT_DIR/bash/travel/swamp/350zone/to350Gate.sh

# TO BOSS
# ====================
# Open map
tap_openMap
sleep 0.5
# Click boss zone
adb_tap 2125 705
sleep 0.2
# Close map
tap_closeMap
sleep 19
