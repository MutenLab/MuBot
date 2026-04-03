#!/bin/bash
# TELEPORT TO LORENCIA
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

# Open map
sleep 0.5
tap_openMap
# Click Lorencia title
sleep 0.5
adb_tap 400 290 # Migrated
