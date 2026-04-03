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
# TO GOLDEN 410
# ====================
# Open map
tap_openMap
sleep 0.5
# Click golden zone
adb_tap 2005 590
sleep 0.2
# Close map
tap_closeMap

# Use travel time to perform optional tasks
# Alternate between recycle+validation or game check
if [ "$performGameValidation" = "true" ]; then
    # Only do game check (no recycle, no validation)
    runDuringTravelling 14 false "none" true  # remainTime=14s, performRecycle=false, validationType=none, performGameValidation=true
    if [ $? -ne 0 ]; then
        exit 1
    fi
else
    # Do recycle and validation (no game check)
    runDuringTravelling 14 true "$validationType" false  # remainTime=14s, performRecycle=true, validationType, performGameValidation=false
fi
