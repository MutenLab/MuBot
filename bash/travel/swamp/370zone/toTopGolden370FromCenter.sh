#!/bin/bash
# MOVE TO GOLDEN 350 FROM RIGHT GATE
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

# TO TOP GATE
# ==============
$PROJECT_DIR/bash/travel/swamp/370zone/to370Gate.sh

# TO TOP GOLDEN 370
# ====================
# Open map
tap_openMap
sleep 0.5
# Click golden zone
adb_tap 1720 410
sleep 0.2
# Close map
tap_closeMap
sleep 10
# Teleport with skill to save time
#adb_text 4
