#!/bin/bash
# Parameters:
#   $1 - validationType (default "none") - Valid values: "angel", "satan", "none"
#   $2 - performGameValidation (default "false") - Whether to check if game is running
# ==================================================

# Parameters
validationType=${1:-"none"}  # Default to none validation if not specified
performGameValidation=${2:-"false"}  # Default to false if not specified

# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh

sleep 2
# TO MOBS
# ====================
# Open map
tap_openMap
sleep 0.5
# Click mob zone
adb_tap 1575 375
sleep 0.5
# Close map
tap_closeMap

# Use travel time to perform optional tasks
runDuringTravelling 12 true "$validationType" true 0  # remainTime=12s, performRecycle=true, validationType, performGameValidation=true, expectedLocation=0(No check)
exit_code=$?
if [ $exit_code -ne 0 ]; then
    exit $exit_code
fi
