#!/bin/bash

# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

# ENTER EVENT
# ================
echo "[$(date '+%H:%M:%S')] Going to Blood Castle..."
# Open Daily Goals window
openDailyGoals
# Find and tap event in the daily goals grid
sleep 1
findAndTapDailyGoalEvent $DG_BLOOD_CASTLE
if [ $? -ne 0 ]; then
    echo "[$(date '+%H:%M:%S')] Blood Castle event not found. Exiting."
    exit 1
fi
# Wait to arrive
sleep 15
# Click on last level
tap_event_last_level
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

# CHANGE PLAN AND PICKUP BEFORE EVENT
# ================
if [ "$PLAN_BEFORE_BLOOD_CASTLE" -ne 0 ]; then
    changePlan $PLAN_BEFORE_BLOOD_CASTLE
fi
if [ "$EVENT_CHANGE_GOLD_PICKUP" = "true" ]; then
    setGoldPickup false
fi

# RECYCLER & SATAN VALIDATION
# ================
# During wait time
runDuringTravelling 15 true "satan"
tap_more_top_button

# WAIT COUNTDOWN & START EVENT
# ================
eventStartEpoch=$(waitToStartEvent)

# POSITION
# ================
# Move to better spot
tap_openMap
sleep 1
tap_event_bc_best_location
sleep 0.5
# Close Map
tap_closeMap
sleep 15
# Click auto attack to start
tap_auto
echo "[$(date '+%H:%M:%S')] Arrived to good spot. Attacking..."

# ATTACK DURING EVENT
# ================
runWhileEvent $eventStartEpoch

waitToEndEvent

# CHANGE PLAN AND PICKUP AFTER EVENT
# ================
if [ "$PLAN_AFTER_BLOOD_CASTLE" -ne 0 ]; then
    changePlan $PLAN_AFTER_BLOOD_CASTLE
fi
if [ "$EVENT_CHANGE_GOLD_PICKUP" = "true" ]; then
    setGoldPickup true
fi

# LEAVE PARTY
# ================
leaveParty
sleep 0.5
