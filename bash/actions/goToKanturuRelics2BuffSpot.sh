#!/bin/bash
# Use first argument to teleport or not
teleport=${1:-true}
# TELEPORT TO SWAMP OF PEACE
# ==================================================
if [ $teleport = true ]; then
/Users/icerrate/AndroidStudioProjects/bot/bash/teleport/toKanturuRelics2.sh
fi

sleep 4
/Users/icerrate/AndroidStudioProjects/bot/bash/actions/switchWire.sh 1 &
switchWirePID=$!              # Save PID
wait $switchWirePID           # Wait to ensure it's terminated

# MOVE TO SPOT
# ==================================================
/Users/icerrate/AndroidStudioProjects/bot/bash/travel/kanturuRelics2/toBuffSpotBot.sh
# Give time to elf to buff character
sleep 20
echo "[$(date '+%H:%M:%S')] Buffed"
