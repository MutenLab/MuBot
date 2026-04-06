#!/bin/bash
# AUTO PLAY SKILL
# Repeatedly press a skill key with cooldown while checking for character death
# If character dies, returns exit code 2 (force buff)
#
# Parameters:
#   $1 - Duration in seconds (optional, 0 = infinite)
#   $2 - Key code to press (default 5)
#   $3 - Cooldown in seconds (default 3)
#   $4 - Check Devil Square event (default false)
#   $5 - Check Blood Castle event (default false)
#
# Exit codes:
#   0  = Duration completed or cancelled normally
#   1  = Skip to next cycle ("n" key)
#   2  = Force buff ("b" key or character died)
#   3  = Event time detected (interrupt for event)
#   10 = Abort execution (other keys)
# ==================================================

source $PROJECT_DIR/config/variables.sh
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

duration=${1:-0}           # 0 = infinite
keyCode=${2:-5}            # Default key code 5
cooldown=${3:-3}           # Default 3 second cooldown
checkDevilSquare=${4:-false}   # Check Devil Square event time
checkBloodCastle=${5:-false}   # Check Blood Castle event time

skillCount=0
lastEventCheck=0           # Track last event time check
isPaused=false
pauseFlagFile="$MUBOT_TEMP_DIR/mubot_skill_paused"
startTime=$(date +%s)

# Check for expired popup before starting
detectAndCloseExpiredPopup

while true; do
    # Check duration limit (if not infinite)
    if [ $duration -gt 0 ]; then
        currentTime=$(date +%s)
        elapsed=$((currentTime - startTime))
        if [ $elapsed -ge $duration ]; then
            rm -f "$pauseFlagFile"
            exit 0
        fi
    fi

    # Check for event time every 30 seconds (if enabled)
    if [ "$checkDevilSquare" = true ] || [ "$checkBloodCastle" = true ]; then
        currentTime=$(date +%s)
        if [ $((currentTime - lastEventCheck)) -ge 30 ]; then
            lastEventCheck=$currentTime
            eventDetected=false
            if [ "$checkDevilSquare" = true ] && isDevilSquareTime; then
                eventDetected=true
            elif [ "$checkBloodCastle" = true ] && isBloodCastleTime; then
                eventDetected=true
            fi
            if [ "$eventDetected" = true ]; then
                echo "[$(date '+%H:%M:%S')] Event time detected. Interrupting cycle..."
                rm -f "$pauseFlagFile"
                tap_attack
                exit 3
            fi
        fi
    fi

    # Press the skill and check for death every 3 presses
    if [ "$isPaused" = false ]; then
        tap_skill_5
        ((skillCount++))

        # Check if character died every 3 skill presses
        if [ $((skillCount % 3)) -eq 0 ]; then
            sleep 0.5
            validateCharacterIsDead
            if [ $? -eq 0 ]; then
                echo "[$(date '+%H:%M:%S')] Character died. Forcing buff..."
                rm -f "$pauseFlagFile"
                exit 2
            fi
        fi
    fi

    # Wait for cooldown while checking for user input
    elapsed=0
    while [ $elapsed -lt $cooldown ]; do
        read -t 1 -n 1 key
        if [ $? = 0 ]; then
            if [[ $key == "p" ]]; then
                if [ "$isPaused" = false ]; then
                    echo "[$(date '+%H:%M:%S')] Paused. Press 'p' again to resume..."
                    isPaused=true
                    touch "$pauseFlagFile"
                else
                    echo "[$(date '+%H:%M:%S')] Resumed."
                    isPaused=false
                    rm -f "$pauseFlagFile"
                fi
            elif [[ $key == "c" ]]; then
                echo "[$(date '+%H:%M:%S')] Cancelled. Total skills pressed: $skillCount"
                rm -f "$pauseFlagFile"
                exit 0
            elif [[ $key == "n" ]]; then
                echo "[$(date '+%H:%M:%S')] Skipping..."
                rm -f "$pauseFlagFile"
                exit 1
            elif [[ $key == "b" ]]; then
                echo "[$(date '+%H:%M:%S')] Forcing buff..."
                rm -f "$pauseFlagFile"
                exit 2
            else
                echo "[$(date '+%H:%M:%S')] Aborting..."
                rm -f "$pauseFlagFile"
                exit 10
            fi
        fi

        if [ "$isPaused" = false ]; then
            ((elapsed++))
        fi
    done
done
