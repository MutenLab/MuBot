#!/bin/bash

# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

# ENTER EVENT
# ================
echo "[$(date '+%H:%M:%S')] Going to Blood Castle..."
$PROJECT_DIR/bash/actions/openEventWindow.sh
sleep 1
clickEventGoButton "blood"
sleep 15
# Click on last level
tap_event_last_level
sleep 0.5
screenshotName="BC_$(date '+%H.%M').png"
adb_screencap > "$HOME/Desktop/$screenshotName"
echo "[$(date '+%H:%M:%S')] Screenshot saved: $screenshotName"
sleep 0.5
# Enter button
tap_event_enter
sleep 5
echo "[$(date '+%H:%M:%S')] Entering Event..."

# Check if we are at correct location
currentLocation=$(getLocation)
if [ "$currentLocation" -ne "$LOC_BLOOD_CASTLE" ]; then
    currentName=$(getLocationName $currentLocation)
    echo "[$(date '+%H:%M:%S')] ERROR: Not at Blood Castle (at $currentName). Aborting event..."
    exit 1
fi
echo "[$(date '+%H:%M:%S')] Confirmed at Blood Castle."

# CHANGE TO BLIZZARD PLAN
# ================
changePlan 2

# RECYCLER & SATAN VALIDATION
# ================
# During wait time
runDuringTravelling 15 true "satan"

# WAIT COUNTDOWN & START EVENT
# ================
eventStartEpoch=$(waitToStartEvent)

# POSITION
# ================
# Move to better spot
tap_openMap
sleep 1
tap_event_bc_best_location
sleep 15
# Click auto attack to start
tap_auto
echo "[$(date '+%H:%M:%S')] Arrived to good spot. Attacking..."

# ATTACK DURING EVENT
# ================
runWhileEvent $eventStartEpoch

waitToEndEvent

# LEAVE PARTY
# ================
leaveParty
sleep 0.5
