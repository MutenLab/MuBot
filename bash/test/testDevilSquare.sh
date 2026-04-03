#!/bin/bash
# Test script for Devil Square event
# ==================================================

source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Running Devil Square test..."
$PROJECT_DIR/bash/event/devilSquare.sh
echo "[$(date '+%H:%M:%S')] Devil Square test finished."
