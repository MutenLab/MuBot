#!/bin/bash
# Test script for checkRemainTimeForEventToStart
# ==================================================

source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh

echo "[$(date '+%H:%M:%S')] Testing checkRemainTimeForEventToStart..."
remainTime=$(checkRemainTimeForEventToStart)
exitCode=$?
echo "[$(date '+%H:%M:%S')] Result: ${remainTime}s (exit code: $exitCode)"

if [ $exitCode -eq 0 ] && [ "$remainTime" -gt 0 ]; then
    echo "[$(date '+%H:%M:%S')] Timer detected: ${remainTime}s remaining"
else
    echo "[$(date '+%H:%M:%S')] No timer detected. Would use fallback 105s."
fi
