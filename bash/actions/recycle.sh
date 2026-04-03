#!/bin/bash

# Load configuration
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/visionUtils.sh

sleep 1
# Open inventory
tap_open_inventory
# Open recycle window
sleep 0.5
tap_inventory_recycle
# Click recycle now
sleep 0.5
tap_inventory_recycle_confirm
sleep 0.5
# Check if recycle reminder popup appeared (MU Coin Bonus Card)
if isRecyclePopupVisible; then
    echo "[$(date '+%H:%M:%S')] Recycle popup detected, clicking Recycle button..."
    tap_inventory_recycle_ads
    sleep 0.5
fi
# Click to close popup with recycle materials
sleep 0.2
tap_inventory_recycle_confirm
# Close recycle windows
sleep 0.5
tap_inventory_close
sleep 1
