#!/bin/bash
# Parameters:
#   $1 - validationType (default "none") - Valid values: "angel", "satan", "none"
#   $2 - performGameValidation (default "false") - Whether to check if game is running
# ==================================================

# Parameters
validationType=${1:-"none"}  # Default to none validation if not specified
performGameValidation=${2:-"false"}  # Default to false if not specified

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/farmingUtils.sh

sleep 2
# TO Objective
# ====================
# Open map
tap_openMap
sleep 0.5
# Click mob zone
adb_tap 974 660
sleep 0.5
# Close map
tap_closeMap

# Use travel time to perform optional tasks
# Alternate between recycle+validation or game check
if [ "$performGameValidation" = "true" ]; then
    # Only do game check (no recycle, no validation) + location validation
    runDuringTravelling 16 false "none" true $LOC_EVERSONG_FOREST  # remainTime=16s, performRecycle=false, validationType=none, performGameValidation=true, expectedLocation=EversongForest
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        exit $exit_code
    fi
else
    # Do recycle and validation (no game check)
    runDuringTravelling 16 true "$validationType" false  # remainTime=16s, performRecycle=true, validationType, performGameValidation=false
fi

