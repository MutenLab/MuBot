#!/bin/bash
# MOVE TO GOLDEN ZONE
# We assume character is initially on Raklion 3
# Parameters: [validationType="none"] - Valid values: "angel", "satan", "none"
# ==================================================

# Parameters
validationType=${1:-"none"}  # Default to none validation if not specified

# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh

# Open map
sleep 2
tap_openMap
# Click golden zone
sleep 0.5
adb_tap 1590 530
# Close map
sleep 0.5
tap_closeMap

# Use travel time to perform optional tasks
runDuringTravelling 6 true "$validationType"  # remainTime=6s, performRecycle=true, validationType
tap_auto
