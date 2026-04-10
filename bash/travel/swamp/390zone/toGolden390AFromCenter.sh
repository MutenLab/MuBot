#!/bin/bash
# MOVE TO GOLDEN 390 A FROM CENTER
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh

# TO TOP GATE
# ==============
$PROJECT_DIR/bash/travel/swamp/390zone/to390Gate.sh

# TO GOLDEN 390 A
# ====================
# Open map
tap_openMap
sleep 0.5
# Click golden zone
adb_tap 1680 1095
sleep 0.2
# Close map
tap_closeMap

# Use travel time to perform recycle
runDuringTravelling 5 true "none"
