#!/bin/bash
# MOVE TO RIGHT GATE
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

sleep 2.5
# Open map
tap_openMap
sleep 0.5
# Click top gate zone
adb_tap 1700 785
# Close map
sleep 0.5
tap_closeMap
sleep 3.5
# Arrive to top dragon head gate
adb_tap 850 600
sleep 2
