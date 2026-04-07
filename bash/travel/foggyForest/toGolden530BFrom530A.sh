#!/bin/bash
# Short travel - only runs recycle.
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh

sleep 2
# TO Objective
# ====================
# Open map
tap_openMap
sleep 0.5
# Click mob zone
adb_tap 1080 509
sleep 0.5
# Close map
tap_closeMap

# Use travel time to recycle only
runDuringTravelling 8 true "none" false  # remainTime=8s, performRecycle=true, validationType=none, performGameValidation=false
