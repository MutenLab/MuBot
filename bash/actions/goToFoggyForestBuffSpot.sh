#!/bin/bash
source $PROJECT_DIR/config/variables.sh
# Use first argument to teleport or not
teleport=${1:-true}
# TELEPORT TO SWAMP OF PEACE
# ==================================================
if [ $teleport = true ]; then
$PROJECT_DIR/bash/teleport/toFoggyForest.sh
fi
sleep 4

# Workaround to avoid going back to previous auto target location
tap_attack
adb_tap 940 325
sleep 0.5

$PROJECT_DIR/bash/actions/switchWire.sh 1 &
switchWirePID=$!              # Save PID
wait $switchWirePID           # Wait to ensure it's terminated