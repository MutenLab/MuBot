#!/bin/bash
# WAIT / PAUSE SCRIPT
# Pauses execution and waits for user input
# ==================================================
# Parameters:
#   $1 - maxTime: Maximum wait time in seconds (default: 300)
#        - 0 = infinite wait (no timeout)
#        - N = wait up to N seconds before auto-resuming
#
# Exit codes:
#   1  - Continue/skip (timeout reached OR "n" key pressed)
#   2  - Force buff on next cycle ("b" key pressed)
#   3  - Force Devil Square event on next cycle ("q" key pressed)
#   4  - Force Blood Castle event on next cycle ("r" key pressed)
#   10 - Abort execution (any other key pressed)
#
# Key behaviors during pause:
#   "n" -> 1    = Continue to next cycle
#   "b" -> 2    = Continue and force buff on next cycle
#   "q" -> 3    = Continue and force Devil Square event on next cycle
#   "r" -> 4    = Continue and force Blood Castle event on next cycle
#   "p" or "s"  = Ignored (to avoid accidental abort)
#   Other -> 10 = Abort execution
# ==================================================

pauseFlagFile="/tmp/mubot_paused"

# Load configuration
source $PROJECT_DIR/config/variables.sh

# Parameter: maxTime (default 300 seconds = 5 minutes, 0 = infinite)
maxTime=${1:-300}

if [ $maxTime -eq 0 ]; then
    echo " key pressed. Stop..."
else
    echo " key pressed. Pause..."
fi
touch "$pauseFlagFile"

# Click auto attack to grab items on the mean while
tap_auto

# Track start time for timeout
startTime=$(date +%s)
TIMEOUT=$maxTime

while true; do
    # Check timeout (skip if TIMEOUT is 0 = infinite)
    if [ $TIMEOUT -ne 0 ]; then
        currentTime=$(date +%s)
        elapsed=$((currentTime - startTime))
        if [ $elapsed -ge $TIMEOUT ]; then
            echo "[$(date '+%H:%M:%S')] Wait timeout reached ($TIMEOUT seconds). Continuing..."
            rm -f "$pauseFlagFile"
            exit 1
        fi
    fi

    read -t 1 -n 1 key # Wait 1 second for key
    if [ $? = 0 ]; then # If key pressed
        if [[ $key == "n" ]]; then # Was n
            echo " key pressed. Continuing..."
            rm -f "$pauseFlagFile"
            exit 1
        elif [[ $key == "b" ]]; then # Was b
            echo " key pressed. Forcing buff..."
            rm -f "$pauseFlagFile"
            exit 2
        elif [[ $key == "q" ]]; then # Was q
            echo " key pressed. Forcing Devil Square event..."
            rm -f "$pauseFlagFile"
            exit 3
        elif [[ $key == "r" ]]; then # Was r
            echo " key pressed. Forcing Blood Castle event..."
            rm -f "$pauseFlagFile"
            exit 4
        elif [[ $key == "p" || $key == "s" ]]; then # Was p or s
            # Ignore p or s key to avoid aborting by accident
            continue
        else # Other keys
            echo " key pressed. Aborting..."
            rm -f "$pauseFlagFile"
            exit 10
        fi
    fi
done
