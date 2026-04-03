#!/bin/bash
# Test script for Blood Castle event
# ==================================================

source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Running Blood Castle test..."
$PROJECT_DIR/bash/event/bloodCastle.sh
echo "[$(date '+%H:%M:%S')] Blood Castle test finished."
