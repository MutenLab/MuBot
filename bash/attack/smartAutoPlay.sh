#!/bin/bash
# NEW SMART AUTO PLAY (Boss/Golden)
# Monitors health bar at top of screen to detect if target is alive/dead.
# Supports both boss (red health bar) and golden monster (golden health bar).
#
# Parameters:
#   $1 - Grab items time in seconds (default: 4)
#   $2 - Target type: "boss" or "golden" (default: boss)
#
# Exit codes:
#   0 - Target killed successfully
#   1 - Character died
#   2 - Target was already dead (no health bar at start)
#   3 - Script timeout
# ==================================================

# Parameters
grabItemsTime=${1:-4}            # Seconds to wait while grabbing items (default 4)
targetType=${2:-boss}            # Target type: boss or golden (default boss)

# Constants
SCRIPT_TIMEOUT=240               # Script timeout in seconds (4 minutes)
CHECK_INTERVAL=1                 # Check status every X seconds

# Load utilities
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/farmingUtils.sh

# Check for expired popup before starting
detectAndCloseExpiredPopup

# Select Python detection script based on target type
if [ "$targetType" = "golden" ]; then
    PYTHON_DETECT="/Users/icerrate/AndroidStudioProjects/bot/python/detectGoldenHealthBar.py"
    TARGET_NAME="Golden"
else
    PYTHON_DETECT="/Users/icerrate/AndroidStudioProjects/bot/python/detectBossHealthBar.py"
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
        echo "[$(date '+%H:%M:%S')] Script timeout reached (4 minutes)."
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
            if [ $noTargetCounter -ge 1 ]; then
                # Calculate kill time
                killTime=$(($(date +%s) - scriptStartTime))
                killMins=$((killTime / 60))
                killSecs=$((killTime % 60))
                echo "[$(date '+%H:%M:%S')]✔$TARGET_NAME killed. ($killMins:$(printf '%02d' $killSecs))"
                # Click auto button to grab items
                tap_auto
                sleep $grabItemsTime
                exit 0
            fi
        else
            noTargetCounter=0
        fi

        lastCheckTime=$(date +%s)
    fi
done
