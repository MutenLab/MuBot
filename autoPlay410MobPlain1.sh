#!/bin/bash
# AUTO PLAY 410 MOB PLAIN 1
# Farms at Plain of Winds 410 mob area using autoSkill
# Includes pot buying, buffing, and 28-minute skill cycles
# By pressing "p" key, pauses execution.
# By pressing "c" key during autoSkill, cancels current cycle.
# Other keys cancel process.
# Parameters: [buyPotsCycleAtInit=0] [skipBuffOnStart=false]
# ==================================================

buyPotsCycleAtInit=${1:-0}      # Start cycle for buy potions action
skipBuffOnStart=${2:-false}     # Skip buff on first run (true/false)

# Load configuration and utilities
source "$(dirname "$0")/config/variables.sh"
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Starting auto play at 410 mob zone. Press key to cancel..."

# Constants for configuration
buyPotsCycleAt=6      # Buy potions every 6 cycles
healthPotions=$FARM_HEALTH_POTIONS
manaPotions=$FARM_MANA_POTIONS
pauseFlagFile="/tmp/mubot_paused"

# Buff settings
buffEnabled=true           # Set to false to disable Divine buff

# Aux variables
buyPotsCounter=$buyPotsCycleAtInit
doGameCheck=false          # Alternates between recycle+validation and game check

# Track last buff time - set to current time if skipping buff on start, otherwise 0
if [ "$skipBuffOnStart" = true ]; then
  lastBuffTime=$(date +%s)
  echo "[$(date '+%H:%M:%S')] Skipping buff on first run (will buff in 28 minutes)"
else
  lastBuffTime=0
fi
forceBuff=false            # Flag to force buff on next cycle

# Statistics tracking
startTime=$(date +%s)
startTimeFormatted=$(date '+%d/%m %H:%M:%S')
cyclesCompleted=0
buffCount=0
buyPotionsCount=0
shouldExit=false  # Flag to control script exit

# Function to display statistics and cleanup on exit
displayStats() {
    local endTime=$(date +%s)
    local endTimeFormatted=$(date '+%d/%m %H:%M:%S')
    local totalTime=$((endTime - startTime))
    local hours=$((totalTime / 3600))
    local minutes=$(((totalTime % 3600) / 60))
    local seconds=$((totalTime % 60))

    # Clean up pause flag
    rm -f "$pauseFlagFile" 2>/dev/null

    # Output to stderr to ensure visibility
    echo "" >&2
    echo "=========================================" >&2
    echo "         SESSION STATISTICS" >&2
    echo "=========================================" >&2
    echo "               Start time: $startTimeFormatted" >&2
    echo "                 End time: $endTimeFormatted" >&2
    echo "            Total session: ${hours}h ${minutes}m ${seconds}s" >&2
    echo "             Total cycles: $cyclesCompleted" >&2
    echo "" >&2
    echo "                   Buffed: $buffCount" >&2
    echo "             Store visits: $buyPotionsCount" >&2
    echo "=========================================" >&2
    echo "" >&2
}

# Clean up pause flag on start
rm -f "$pauseFlagFile"

while true; do
  ((cyclesCompleted++))
  # Check if we should exit
  if [ "$shouldExit" = true ]; then
    break
  fi

  # BUY POTIONS TO SURVIVE.
  # ===============================================
  if [ $buyPotsCounter -eq $buyPotsCycleAt ]; then
    performBuyPotions $healthPotions $manaPotions
    if [ $? -ne 0 ]; then
      shouldExit=true
      continue
    fi
    ((buyPotionsCount++))

    # GO BACK TO PLAIN after buying potions
    teleportTo $LOC_PLAIN_OF_WINDS_1

    # Restart buy potions counter
    buyPotsCounter=0
  fi

  # CHECK FOR BUFF (every 28 minutes or if forced)
  # ===============================================
  if [ "$buffEnabled" = true ]; then
    currentTime=$(date +%s)
    timeSinceLastBuff=$((currentTime - lastBuffTime))

    # 28 minutes = 1680 seconds, or forceBuff flag is set
    if [ $timeSinceLastBuff -gt 1680 ] || [ "$forceBuff" = true ]; then
      if [ "$forceBuff" = true ]; then
        echo "[$(date '+%H:%M:%S')] Buff forced by user..."
      else
        echo "[$(date '+%H:%M:%S')] Buff needed (last buff: $((timeSinceLastBuff / 60)) minutes ago)..."
      fi

      # Call buff function
      performBuffKanturuRelics2
      ((buffCount++))

      # Update last buff time and reset force flag
      lastBuffTime=$(date +%s)

      # GO BACK TO PLAIN after buffing
      teleportTo $LOC_PLAIN_OF_WINDS_1

      # Reset force flag
      forceBuff=false
    fi
  fi

  echo "[$(date '+%H:%M:%S')] New cycle $cyclesCompleted... (BuyPots: $buyPotsCounter/$buyPotsCycleAt)"

  # GO TO 410 MOB POSITION FROM CENTER.
  # ===============================================
  sleep 1
  # Alternate between recycle+validation and game check
  $PROJECT_DIR/bash/travel/plain1/to410MobsFromCenter.sh "satan" "$doGameCheck" &
  reposition_pid=$!
  # Toggle for next cycle
  if [ "$doGameCheck" = "true" ]; then
    doGameCheck=false
  else
    doGameCheck=true
  fi

  while kill -0 $reposition_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      # Key pressed while traveling - kill process and handle
      kill $reposition_pid 2>/dev/null
      wait $reposition_pid 2>/dev/null
      if [ "$key" = "p" ]; then
        $PROJECT_DIR/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then
          echo "Skipping to next cycle..."
        elif [ $wait_exit_code -eq 2 ]; then
          echo "Forcing buff on next cycle..."
          forceBuff=true
        else
          echo "Preparing stats..."
          shouldExit=true
        fi
      elif [ "$key" = "b" ]; then
        echo " key pressed. Forcing buff on next loop..."
        forceBuff=true
      else
        echo " key pressed. Aborting..."
        shouldExit=true
      fi
      continue
    fi
  done

  wait $reposition_pid
  travel_exit_code=$?

  # Check if game validation failed during travel
  if [ $travel_exit_code -eq 1 ]; then
    sleep 5
    echo "[$(date '+%H:%M:%S')] Game recovered. Returning to Plain 1..."
    teleportTo $LOC_PLAIN_OF_WINDS_1
    sleep 1
    # Equip angel from shortcut
    tap_equipAngel
    sleep 1
    continue
  else
    # RUN AUTO SKILL FOR 28 MINUTES
    # ===============================================
    echo "[$(date '+%H:%M:%S')] Arrived to 410 mob spot. Starting auto skill..."

    # Run autoSkill for 28 minutes (1680 seconds)
    # Default: key code 5, 3 second cooldown
    autoSkill 1680

    echo "[$(date '+%H:%M:%S')] Auto skill cycle completed."

    # Increment buy pots counter
    ((buyPotsCounter++))
  fi
done

# Display statistics before exiting
displayStats
