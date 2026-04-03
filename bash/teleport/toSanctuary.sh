#!/bin/bash
# TELEPORT TO SANCTUARY
# Usage: toSanctuary.sh <level>  (1-6)
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

SANCTUARY_LEVEL=${1:-2}

# Validate level
if [ "$SANCTUARY_LEVEL" -lt 1 ] || [ "$SANCTUARY_LEVEL" -gt 6 ]; then
    echo "[$(date '+%H:%M:%S')] Error: Invalid sanctuary level: $SANCTUARY_LEVEL (must be 1-6)" >&2
    exit 1
fi

# Map level to Y coordinate for level selection
case $SANCTUARY_LEVEL in
    1) LEVEL_Y=280 ;;
    2) LEVEL_Y=345 ;;
    3) LEVEL_Y=410 ;;
    4) LEVEL_Y=475 ;;
    5) LEVEL_Y=535 ;;
    6) LEVEL_Y=600 ;;
esac

$PROJECT_DIR/bash/teleport/toDivine.sh

sleep 10
# Open map
tap_openMap
sleep 0.5
# Click clear zone
adb_tap 1130 550
sleep 0.5
# Close map
tap_closeMap

sleep 2
# Click entrance
adb_tap 1040 286
sleep 2
# Select level
adb_tap 750 $LEVEL_Y

sleep 0.5
# Click Enter
adb_tap 960 825
sleep 3
