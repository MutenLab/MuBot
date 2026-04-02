#!/bin/bash
# MOVE TO GOLDEN ZONE
# We assume character is initially on Raklion 3
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/farmingUtils.sh

sleep 3
# Open map
tap_openMap
sleep 0.5
# Click buff spot
adb_tap 1560 1015
sleep 0.5
# Close map
tap_closeMap
sleep 1
    
# forceAutoParty

sleep 12
