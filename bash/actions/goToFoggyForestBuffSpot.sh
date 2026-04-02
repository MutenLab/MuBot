#!/bin/bash
# Use first argument to teleport or not
teleport=${1:-true}
# TELEPORT TO SWAMP OF PEACE
# ==================================================
if [ $teleport = true ]; then
/Users/icerrate/AndroidStudioProjects/bot/bash/teleport/toFoggyForest.sh
fi

sleep 4
/Users/icerrate/AndroidStudioProjects/bot/bash/actions/switchWire.sh 1 &
switchWirePID=$!              # Save PID
wait $switchWirePID           # Wait to ensure it's terminated
