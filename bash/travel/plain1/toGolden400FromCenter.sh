#!/bin/bash
# MOVE TO GOLDEN 400 FROM CENTER
# We assume character is initially on Plain of Four Winds 1
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh

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

# Use travel time to perform recycle + game check
runDuringTravelling 30 true "none" true
