#!/bin/bash
# Test script for end of event detection
# ==================================================

source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Testing end of event detection..."

# Wait for "Event is over" screen, check every 5 seconds (timeout 30s)
eventOverTimeout=30
eventOverElapsed=0
while [ $eventOverElapsed -lt $eventOverTimeout ]; do
    if isEventOver; then
        echo "[$(date '+%H:%M:%S')] Event is over screen detected."
        sleep 1
        # Click window close button
        tap_event_scoreboard_close
        break
    fi
    sleep 5
    eventOverElapsed=$((eventOverElapsed + 5))
done
if [ $eventOverElapsed -ge $eventOverTimeout ]; then
    echo "[$(date '+%H:%M:%S')] Timeout waiting for event over screen. Closing anyway..."
    # Click window close button
    tap_event_scoreboard_close
fi

echo "[$(date '+%H:%M:%S')] Exit event..."
sleep 2

# LEAVE PARTY
leaveParty
sleep 0.5

echo "[$(date '+%H:%M:%S')] Test finished."
