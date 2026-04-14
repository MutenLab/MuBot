#!/bin/bash
# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

# ENTER EVENT
# ================
echo "[$(date '+%H:%M:%S')] Going to Devil Square..."
$PROJECT_DIR/bash/actions/openEventWindow.sh
# Open Daily Goals window
openDailyGoals
# Find and tap event in the daily goals grid
sleep 1
findAndTapDailyGoalEvent $DG_DEVIL_SQUARE
if [ $? -ne 0 ]; then
    echo "[$(date '+%H:%M:%S')] Devil Square event not found. Exiting."
    exit 1
fi
# Wait to arrive
sleep 12
# Click on last level
tap_event_last_level
sleep 0.5
# Enter button
tap_event_enter
sleep 5
echo "[$(date '+%H:%M:%S')] Entering Event..."

# Check if we are at correct location
currentLocation=$(getLocation)
if [ "$currentLocation" -ne "$LOC_DEVIL_SQUARE" ]; then
    currentName=$(getLocationName $currentLocation)
    echo "[$(date '+%H:%M:%S')] ERROR: Not at Devil Square (at $currentName). Aborting event..."
    exit 1
fi
echo "[$(date '+%H:%M:%S')] Confirmed at Devil Square."

# POSITION
# ================
# Open Map
tap_openMap
sleep 0.5
# Go to best spot on map
tap_event_ds_best_location
sleep 0.5
# Close Map
tap_closeMap
sleep 1

# CHANGE PLAN AND PICKUP BEFORE EVENT
# ================
if [ "$PLAN_BEFORE_DEVIL_SQUARE" -ne 0 ]; then
    changePlan $PLAN_BEFORE_DEVIL_SQUARE
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

# ATTACK DURING EVENT
# ================
runWhileEvent $eventStartEpoch

waitToEndEvent

# CHANGE PLAN AND PICKUP AFTER EVENT
# ================
if [ "$PLAN_AFTER_DEVIL_SQUARE" -ne 0 ]; then
    changePlan $PLAN_AFTER_DEVIL_SQUARE
fi
if [ "$EVENT_CHANGE_GOLD_PICKUP" = "true" ]; then
    setGoldPickup true
fi

# LEAVE PARTY
# ================
leaveParty
sleep 0.5
