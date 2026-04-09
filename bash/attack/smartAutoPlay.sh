#!/bin/bash
# NEW SMART AUTO PLAY (Boss/Golden)
# Monitors health bar at top of screen to detect if target is alive/dead.
# Supports both boss (red health bar) and golden monster (golden health bar).
#
# Parameters:
#   $1 - Target type: "boss" or "golden" (default: boss)
#
# Pickup time is read from local.properties (pickup.items.boss / pickup.items.golden).
#
# Exit codes:
#   0 - Target killed successfully
#   1 - Character died
#   2 - Target was already dead (no health bar at start)
#   3 - Script timeout
# ==================================================

# Parameters
targetType=${1:-boss}            # Target type: boss or golden (default boss)

# Resolve grab items time from local.properties based on target type
if [ "$targetType" = "golden" ]; then
    grabItemsTime=$PICKUP_ITEMS_GOLDEN
else
    grabItemsTime=$PICKUP_ITEMS_BOSS
fi

# Constants
SCRIPT_TIMEOUT=$AUTOPLAY_ATTACK_TIMEOUT  # Script timeout in seconds (from local.properties)
CHECK_INTERVAL=$AUTOPLAY_HEALTHBAR_CHECK_INTERVAL  # Check status every X seconds (from local.properties)

# Load utilities
source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh

# Check for expired popup before starting
detectAndCloseExpiredPopup

# Select Python detection script based on target type
if [ "$targetType" = "golden" ]; then
    PYTHON_DETECT="$PROJECT_DIR/python/detectGoldenHealthBar.py"
    TARGET_NAME="Golden"
else
    PYTHON_DETECT="$PROJECT_DIR/python/detectBossHealthBar.py"
    TARGET_NAME="Boss"
fi

# Check if target health bar is visible
checkTargetAlive() {
    local status=$(adb_screencap | python3 "$PYTHON_DETECT" --stdin 2>/dev/null)
    if [ "$status" = "alive" ]; then
        return 0  # Target is alive
    else
        return 1  # Target is dead
    fi
}

echo "[$(date '+%H:%M:%S')] Combat mode ($TARGET_NAME Health Bar Detection)..."

# Auto attack to target and show health bar
tap_auto  # Click attack
sleep 2

# Check if target is already dead at start
checkTargetAlive
if [ $? -ne 0 ]; then
    echo "[$(date '+%H:%M:%S')]✗$TARGET_NAME was already dead."
    exit 2
fi

# Counters
noTargetCounter=0

# Timers
scriptStartTime=$(date +%s)
lastCheckTime=$(date +%s)

while true; do
    # Click attack
    tap_attack
    sleep 0.5

    # Check timers
    currentTime=$(date +%s)
    elapsedTime=$((currentTime - lastCheckTime))
    scriptElapsedTime=$((currentTime - scriptStartTime))

    # Check script timeout
    if [ $scriptElapsedTime -ge $SCRIPT_TIMEOUT ]; then
        echo "[$(date '+%H:%M:%S')] Script timeout reached ($((SCRIPT_TIMEOUT / 60)) minutes)."
        exit 3
    fi

    # Check every CHECK_INTERVAL seconds
    if [ $elapsedTime -ge $CHECK_INTERVAL ]; then
        # Check if character died
        validateCharacterIsDead
        if [ $? -eq 0 ]; then
            echo "[$(date '+%H:%M:%S')]☠Character died."
            exit 1
        fi

        # Check if target is still alive
        checkTargetAlive
        if [ $? -ne 0 ]; then
            ((noTargetCounter++))
            if [ $noTargetCounter -ge $AUTOPLAY_HEALTHBAR_TIMES_KILLED ]; then
                # Calculate kill time
                killTime=$(($(date +%s) - scriptStartTime))
                killMins=$((killTime / 60))
                killSecs=$((killTime % 60))
                echo "[$(date '+%H:%M:%S')]✔$TARGET_NAME killed. ($killMins:$(printf '%02d' $killSecs))"
                # Click auto button to grab items
                tap_auto
                sleep $grabItemsTime
                # Click attack to make sure we stop auto but we keep attacking if boss still alive
                # due to low health bar giving false dead status
                tap_attack
                exit 0
            fi
        else
            noTargetCounter=0
        fi

        lastCheckTime=$(date +%s)
    fi
done
