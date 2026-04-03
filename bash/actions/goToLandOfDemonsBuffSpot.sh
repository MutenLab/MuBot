#!/bin/bash
# Use first argument to teleport or not
teleport=${1:-true}
# TELEPORT TO SWAMP OF PEACE
# ==================================================
if [ $teleport = true ]; then
$PROJECT_DIR/bash/teleport/toLandOfDemons.sh
fi

sleep 4
$PROJECT_DIR/bash/actions/switchWire.sh 1 &
switchWirePID=$!              # Save PID
wait $switchWirePID           # Wait to ensure it's terminated

# MOVE TO SPOT
# ==================================================
$PROJECT_DIR/bash/travel/toLandOfDemons/toBuffSpot.sh
# Give time to elf to buff character
sleep 15
echo "[$(date '+%H:%M:%S')] Buffed"
