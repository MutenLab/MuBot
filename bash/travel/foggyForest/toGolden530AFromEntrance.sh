#!/bin/bash
# Always runs recycle, validation, game validation, and location validation.
# Parameters:
#   $1 - validationType (default "none") - Valid values: "angel", "satan", "none"
# ==================================================

# Parameters
validationType=${1:-"none"}  # Default to none validation if not specified

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
adb_tap 1188 509
sleep 0.5
# Close map
tap_closeMap

# Use travel time to perform recycle + satan validation + game check + location validation
runDuringTravelling 44 true "$validationType" true $LOC_FOGGY_FOREST  # remainTime=44s, performRecycle=true, validationType, performGameValidation=true, expectedLocation=FoggyForest
exit_code=$?
if [ $exit_code -ne 0 ]; then
    exit $exit_code
fi
