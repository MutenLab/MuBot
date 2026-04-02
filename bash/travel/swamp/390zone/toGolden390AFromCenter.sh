#!/bin/bash
# MOVE TO GOLDEN 350 FROM RIGHT GATE
# We assume character is initially on Swamp of peace
# ==================================================

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

# TO TOP GATE
# ==============
/Users/icerrate/AndroidStudioProjects/bot/bash/travel/swamp/390zone/to390Gate.sh

# TO GOLDEN 390 A
# ====================
# Open map
tap_openMap
sleep 0.5
# Click golden zone
adb_tap 1680 1095
sleep 0.2
# Close map
tap_closeMap
sleep 5
