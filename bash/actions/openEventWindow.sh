#!/bin/bash
# Opens the event window and selects the Event tab
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

# Tap top-right menu
tap_more_top_button
sleep 0.5
# Tap daily goal / event button
tap_more_top_daily_goal
sleep 0.5
# Select Event tab
tap_daily_goal_event_tab
sleep 0.5
