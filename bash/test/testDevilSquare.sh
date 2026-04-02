#!/bin/bash
# Test script for Devil Square event
# ==================================================

source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/farmingUtils.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Running Devil Square test..."
/Users/icerrate/AndroidStudioProjects/bot/bash/event/devilSquare.sh
echo "[$(date '+%H:%M:%S')] Devil Square test finished."
