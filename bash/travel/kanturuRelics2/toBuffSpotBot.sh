#!/bin/bash
# MOVE TO GOLDEN ZONE
# We assume character is initially on Raklion 3
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh

sleep 3
# Open map
tap_openMap
sleep 0.5
# Click buff spot
adb_tap 1070 295
sleep 0.5
# Close map
tap_closeMap
sleep 1
    
forceAutoParty

sleep 9
