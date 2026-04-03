#!/bin/bash
# AUTO PLAY MOB ABYSSAL FEREA
# Farms at Abyssal Ferea mob area using autoSkill
# Includes pot buying, buffing, events, and 28-minute skill cycles
# By pressing "p" key, pauses execution.
# By pressing "c" key during autoSkill, cancels current cycle.
# Other keys cancel process.
# Parameters: [buyPotsCycleAtInit=0]
# ==================================================

buyPotsCycleAtInit=${1:-0}      # Start cycle for buy potions action

# Load configuration and utilities
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/farmingUtils.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Starting auto play at Abyssal Ferea mob zone. Press key to cancel..."

# Constants for configuration
buyPotsCycleAt=6      # Buy potions every 6 cycles
healthPotions=2500    # Health pots to buy
manaPotions=2500      # Mana pots to buy
pauseFlagFile="/tmp/mubot_paused"

# Event settings
devilSquareEnabled=true    # Set to false to disable Devil Square
bloodCastleEnabled=true    # Set to false to disable Blood Castle

# Aux variables
buyPotsCounter=$buyPotsCycleAtInit

# Aux variables for buff timing
lastBuffTime=0
forceBuff=false            # Flag to force buff on next cycle

# Statistics tracking
startTime=$(date +%s)
startTimeFormatted=$(date '+%d/%m %H:%M:%S')
cyclesCompleted=0
buffCount=0
buyPotionsCount=0
devilSquareCount=0
bloodCastleCount=0
shouldExit=false  # Flag to control script exit

# Event failure tracking (max 2 attempts per hour per event)
dsFailCount=0
bcFailCount=0
dsFailHour=-1
bcFailHour=-1

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
    echo "            Devil Squares: $devilSquareCount" >&2
    echo "            Blood Castles: $bloodCastleCount" >&2
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

  # Always teleport to map at start of each cycle
  needToTeleportToMap=true

  # Check for expired popup
  detectAndCloseExpiredPopup

  # CHECK FOR EVENTS FIRST (before buff/potions which consume time)
  # ===============================================
  # CHECK FOR DEVIL SQUARE EVENT
  # ===============================================
  if [ "$devilSquareEnabled" = true ] && isDevilSquareTime; then
    # Reset fail counter if hour changed
    currentHour=$(date '+%H')
    if [ "$currentHour" != "$dsFailHour" ]; then
      dsFailCount=0
      dsFailHour=$currentHour
    fi
    if [ $dsFailCount -ge 2 ]; then
      echo "[$(date '+%H:%M:%S')] Devil Square skipped (failed $dsFailCount times this hour)"
    else
      echo "[$(date '+%H:%M:%S')] Devil Square event time detected! (attempt $((dsFailCount + 1))/2)"
      currentTime=$(date +%s)
      timeSinceLastBuff=$((currentTime - lastBuffTime))
      buffRemaining=$((1800 - timeSinceLastBuff))
      if [ $buffRemaining -lt 720 ]; then
        echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (<12min). Buffing before event..."
        performBuffFoggyForest
        lastBuffTime=$(date +%s)
      else
        echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (>=12min). Skipping buff."
      fi
      /Users/icerrate/AndroidStudioProjects/bot/bash/event/devilSquare.sh
      if [ $? -eq 0 ]; then
        ((devilSquareCount++))
      else
        ((dsFailCount++))
        echo "[$(date '+%H:%M:%S')] Devil Square failed ($dsFailCount/2 attempts this hour)"
        needToTeleportToMap=true
        continue
      fi
      needToTeleportToMap=true
    fi
  fi
  # CHECK FOR BLOOD CASTLE EVENT
  # ===============================================
  if [ "$bloodCastleEnabled" = true ] && isBloodCastleTime; then
    currentHour=$(date '+%H')
    if [ "$currentHour" != "$bcFailHour" ]; then
      bcFailCount=0
      bcFailHour=$currentHour
    fi
    if [ $bcFailCount -ge 2 ]; then
      echo "[$(date '+%H:%M:%S')] Blood Castle skipped (failed $bcFailCount times this hour)"
    else
      echo "[$(date '+%H:%M:%S')] Blood Castle event time detected! (attempt $((bcFailCount + 1))/2)"
      currentTime=$(date +%s)
      timeSinceLastBuff=$((currentTime - lastBuffTime))
      buffRemaining=$((1800 - timeSinceLastBuff))
      if [ $buffRemaining -lt 720 ]; then
        echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (<12min). Buffing before event..."
        performBuffFoggyForest
        lastBuffTime=$(date +%s)
      else
        echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (>=12min). Skipping buff."
      fi
      /Users/icerrate/AndroidStudioProjects/bot/bash/event/bloodCastle.sh
      if [ $? -eq 0 ]; then
        ((bloodCastleCount++))
      else
        ((bcFailCount++))
        echo "[$(date '+%H:%M:%S')] Blood Castle failed ($bcFailCount/2 attempts this hour)"
        needToTeleportToMap=true
        continue
      fi
      needToTeleportToMap=true
    fi
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
    needToTeleportToMap=true

    # Restart buy potions counter
    buyPotsCounter=0
  fi

  # CHECK FOR BUFF (every 28 minutes or if forced)
  # ===============================================
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
    performBuffFoggyForest
    ((buffCount++))

    # Update last buff time and reset force flag
    lastBuffTime=$(date +%s)
    needToTeleportToMap=true

    # Reset force flag
    forceBuff=false
  fi

  # TELEPORT TO ABYSSAL FEREA IF NEEDED
  # ===============================================
  if [ "$needToTeleportToMap" = true ]; then
    teleportTo $LOC_ABYSSAL_FEREA
  fi

  echo "[$(date '+%H:%M:%S')] New cycle $cyclesCompleted... (BuyPots: $buyPotsCounter/$buyPotsCycleAt)"

  # GO TO MOB POSITION FROM CENTER.
  # ===============================================
  sleep 1
  # Alternate between recycle+validation and game check
  /Users/icerrate/AndroidStudioProjects/bot/bash/travel/abyssalFerea/toMobsFromCenter.sh "satan" true &
  reposition_pid=$!

  while kill -0 $reposition_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      # Key pressed while traveling - kill process and handle
      kill $reposition_pid 2>/dev/null
      wait $reposition_pid 2>/dev/null
      if [ "$key" = "p" ]; then
        /Users/icerrate/AndroidStudioProjects/bot/bash/actions/wait.sh
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
    echo "[$(date '+%H:%M:%S')] Game recovered. Returning to Abyssal Ferea..."
    teleportTo $LOC_ABYSSAL_FEREA
    sleep 1
    tap_equipSatan
    sleep 1
    continue
  else
    tap_auto

    # RUN AUTO SKILL FOR REMAINING BUFF TIME
    # ===============================================
    # Calculate auto skill duration
    currentTime=$(date +%s)
    timeSinceLastBuff=$((currentTime - lastBuffTime))
    remainingBuffTime=$((1800 - timeSinceLastBuff))

    echo "[$(date '+%H:%M:%S')] Arrived to mob spot. Starting auto skill for $((remainingBuffTime / 60))m $((remainingBuffTime % 60))s..."

    # Run autoPlaySkill with death detection and event time check
    # Parameters: duration, keyCode, cooldown, checkDevilSquare, checkBloodCastle
    /Users/icerrate/AndroidStudioProjects/bot/bash/attack/autoPlaySkill.sh $remainingBuffTime 5 3 $devilSquareEnabled $bloodCastleEnabled
    autoSkill_exit=$?

    # Handle autoPlaySkill exit codes
    if [ $autoSkill_exit -eq 2 ]; then
      # Exit code 2 = force buff (from "b" key or character died)
      echo "[$(date '+%H:%M:%S')] Forcing buff on next cycle..."
      forceBuff=true
    elif [ $autoSkill_exit -eq 3 ]; then
      # Exit code 3 = event time detected, run event immediately
      echo "[$(date '+%H:%M:%S')] Interrupted for event. Running event now..."
      ((buyPotsCounter++))
      currentTime=$(date +%s)
      timeSinceLastBuff=$((currentTime - lastBuffTime))
      buffRemaining=$((1800 - timeSinceLastBuff))
      if isDevilSquareTime; then
        echo "[$(date '+%H:%M:%S')] Devil Square event time!"
        if [ $buffRemaining -lt 720 ]; then
          echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (<12min). Buffing before event..."
          performBuffFoggyForest
          lastBuffTime=$(date +%s)
        else
          echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (>=12min). Skipping buff."
        fi
      elif isBloodCastleTime; then
        echo "[$(date '+%H:%M:%S')] Blood Castle event time!"
        if [ $buffRemaining -lt 720 ]; then
          echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (<12min). Buffing before event..."
          performBuffFoggyForest
          lastBuffTime=$(date +%s)
        else
          echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (>=12min). Skipping buff."
        fi
      fi
      continue
    elif [ $autoSkill_exit -eq 10 ]; then
      shouldExit=true
    fi

    echo "[$(date '+%H:%M:%S')] Auto skill cycle completed."

    # Press attack to stop character movement
    tap_attack

    # Increment buy pots counter
    ((buyPotsCounter++))
  fi
done

# Display statistics before exiting
displayStats
