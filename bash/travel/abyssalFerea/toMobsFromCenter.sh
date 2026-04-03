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
# TO MOBS
# ====================
# Open map
tap_openMap
sleep 0.5
# Click mob zone
adb_tap 1080 581
sleep 0.5
# Close map
tap_closeMap

# Use travel time to perform optional tasks
runDuringTravelling 38 true "none" true 0 true  # remainTime=38s, performRecycle=true, validationType=none, performGameValidation=true, expectedLocation=0, popupValidation=true
if [ $? -ne 0 ]; then
    exit 1
fi
