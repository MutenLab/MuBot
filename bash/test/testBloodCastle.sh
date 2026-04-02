#!/bin/bash
# Test script for Blood Castle event
# ==================================================

source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/farmingUtils.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Running Blood Castle test..."
/Users/icerrate/AndroidStudioProjects/bot/bash/event/bloodCastle.sh
echo "[$(date '+%H:%M:%S')] Blood Castle test finished."
