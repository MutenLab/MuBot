#!/bin/bash
# Test script for checkBuff function
# Usage: ./testCheckBuff.sh [path_to_screenshot]
# If no screenshot provided, uses live adb_screencap
# ==================================================

source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh

# Override adb_screencap if a screenshot path is provided
if [ -n "$1" ]; then
    if [ ! -f "$1" ]; then
        echo "Error: File not found: $1"
        exit 1
    fi
    SCREENSHOT_PATH="$1"
    adb_screencap() {
        cat "$SCREENSHOT_PATH"
    }
    echo "[$(date '+%H:%M:%S')] Testing checkBuff with image: $SCREENSHOT_PATH"
else
    echo "[$(date '+%H:%M:%S')] Testing checkBuff with live screenshot..."
fi

checkBuff
exitCode=$?

if [ $exitCode -eq 0 ]; then
    echo "[$(date '+%H:%M:%S')] Result: Buff ACTIVE (both attack and shield detected)"
else
    echo "[$(date '+%H:%M:%S')] Result: Buff NOT active (exit code: $exitCode)"
fi
