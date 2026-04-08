#!/bin/bash

# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/visionUtils.sh

# Auto attack to make sure top buttons are hidden
tap_auto
sleep 1
tap_auto
sleep 0.5

# Click expand top buttons
tap_more_top_button
sleep 0.5
# Click Daily Goal
tap_more_top_daily_goal

# Find and tap Kundun Trial in the daily goals grid
sleep 1
findAndTapDailyGoalEvent $DG_KUNDUN_TRIAL
if [ $? -ne 0 ]; then
    echo "[$(date '+%H:%M:%S')] Kundun Trial event not found. Exiting."
    exit 1
fi

# Enter event
sleep 0.5
tap_event_kundun_trial_enter
sleep 8

# Move to Kundun spot
tap_openMap
sleep 0.5
tap_event_kundun_trial_best_location
sleep 0.5
tap_closeMap
sleep 6

# Auto attack boss and wait until dead
$PROJECT_DIR/bash/attack/smartAutoPlay.sh boss

sleep 5
