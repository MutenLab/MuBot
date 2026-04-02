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
adb_tap 1590 310
sleep 0.5
# Close map
tap_closeMap

# Use travel time to perform optional tasks
runDuringTravelling 21 true "$validationType" true $LOC_SANCTUARY_2  # remainTime=22s, performRecycle=true, validationType, performGameValidation=true, expectedLocation=Sanctuary2
exit_code=$?
if [ $exit_code -ne 0 ]; then
    exit $exit_code
fi

# Open map
tap_openMap
sleep 0.5
# Click mob zone
adb_tap 1605 325
sleep 0.5
# Close map
tap_closeMap
sleep 1.5
