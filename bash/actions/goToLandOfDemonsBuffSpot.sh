#!/bin/bash
# Use first argument to teleport or not
teleport=${1:-true}
# TELEPORT TO SWAMP OF PEACE
# ==================================================
if [ $teleport = true ]; then
/Users/icerrate/AndroidStudioProjects/bot/bash/teleport/toLandOfDemons.sh
fi

sleep 4
/Users/icerrate/AndroidStudioProjects/bot/bash/actions/switchWire.sh 1 &
switchWirePID=$!              # Save PID
wait $switchWirePID           # Wait to ensure it's terminated

# MOVE TO SPOT
# ==================================================
/Users/icerrate/AndroidStudioProjects/bot/bash/travel/toLandOfDemons/toBuffSpot.sh
# Give time to elf to buff character
sleep 15
echo "[$(date '+%H:%M:%S')] Buffed"
