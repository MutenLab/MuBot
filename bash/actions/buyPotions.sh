#!/bin/bash

# Load configuration
source $PROJECT_DIR/config/variables.sh

# Target potion counts (accept as parameters with defaults)
TARGET_HEALTH_POTIONS=${1:-$FARM_HEALTH_POTIONS}
TARGET_MANA_POTIONS=${2:-$FARM_MANA_POTIONS}
POTIONS_PER_BUY=99

# Read current potion counts from screen
echo "[$(date '+%H:%M:%S')] Reading current potion counts from screen..."
CURRENT_HEALTH_POTIONS=$($PROJECT_DIR/bash/utils/readNumbers.sh 792 1046 61 22) # Migrated
[[ ${#CURRENT_HEALTH_POTIONS} -gt 4 ]] && CURRENT_HEALTH_POTIONS=${CURRENT_HEALTH_POTIONS: -4}
CURRENT_MANA_POTIONS=$($PROJECT_DIR/bash/utils/readNumbers.sh 891 1046 61 22) # Migrated
[[ ${#CURRENT_MANA_POTIONS} -gt 4 ]] && CURRENT_MANA_POTIONS=${CURRENT_MANA_POTIONS: -4}

# Validate that we got numbers
if [[ -z "$CURRENT_HEALTH_POTIONS" ]]; then
    echo "[$(date '+%H:%M:%S')] Warning: Could not read health potion count, defaulting to 0"
    CURRENT_HEALTH_POTIONS=0
fi

if [[ -z "$CURRENT_MANA_POTIONS" ]]; then
    echo "[$(date '+%H:%M:%S')] Warning: Could not read mana potion count, defaulting to 0"
    CURRENT_MANA_POTIONS=0
fi

echo "[$(date '+%H:%M:%S')] Current potions: $CURRENT_HEALTH_POTIONS - $CURRENT_MANA_POTIONS"

# Calculate how many potions we need to buy
HEALTH_NEEDED=$((TARGET_HEALTH_POTIONS - CURRENT_HEALTH_POTIONS))
MANA_NEEDED=$((TARGET_MANA_POTIONS - CURRENT_MANA_POTIONS))

# Make sure we don't have negative values
if [ $HEALTH_NEEDED -lt 0 ]; then
    HEALTH_NEEDED=0
fi

if [ $MANA_NEEDED -lt 0 ]; then
    MANA_NEEDED=0
fi

# Calculate number of buy loops needed (round up using integer division)
healthPotsCount=$(( (HEALTH_NEEDED + POTIONS_PER_BUY - 1) / POTIONS_PER_BUY ))
manaPotsCount=$(( (MANA_NEEDED + POTIONS_PER_BUY - 1) / POTIONS_PER_BUY ))

# If already at target, skip buying
if [ $healthPotsCount -eq 0 ] && [ $manaPotsCount -eq 0 ]; then
    echo "Already at target potion counts. Skipping purchase."
    exit 0
fi

sleep 2
# Open inventory
tap_open_inventory
# Click on shop button
sleep 0.5
tap_inventory_shop
# Click teleport now
sleep 0.5
tap_inventory_shop_teleport
# Wait to load shop
sleep 5
# Buy health potions
counter=1
while [ $counter -le $healthPotsCount ]
do
  tap_shop_health_potion
  sleep 0.5
  tap_shop_health_potion
  ((counter++))
done
sleep 2
# Buy mana potions
counter=2
while [ $counter -le $manaPotsCount ]
do
  tap_shop_mana_potion
  sleep 0.5
  tap_shop_mana_potion
  ((counter++))
done
sleep 3
# Click outside shop to close screen
tap_close_by_outside
sleep 3
