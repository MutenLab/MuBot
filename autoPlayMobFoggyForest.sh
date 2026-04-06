#!/bin/bash
# AUTO PLAY MOB FOGGY FOREST
# Farms at Foggy Forest mob area using autoSkill
# Includes pot buying, buffing with fallback, events, and 28-minute skill cycles
# By pressing "p" key, pauses execution.
# By pressing "c" key during autoSkill, cancels current cycle.
# Other keys cancel process.
# Parameters: [disableBuff=false]
# ==================================================

disableBuff=${1:-false}         # Disable buff entirely (true/false)
initialBuyPotsCounter=${2:-0}   # Starting buy pots counter (pass 6 to buy on first cycle)

# Load configuration and utilities
source "$(dirname "$0")/config/variables.sh"
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Starting auto play at Foggy Forest mob zone. Press key to cancel..."

# Constants for configuration
buyPotsCycleAt=6      # Buy potions every 6 cycles
healthPotions=$FARM_HEALTH_POTIONS
manaPotions=$FARM_MANA_POTIONS
pauseFlagFile="$MUBOT_TEMP_DIR/mubot_paused"

# Buff settings
if [ "$disableBuff" = true ]; then
  buffEnabled=false
  echo "[$(date '+%H:%M:%S')] Buff disabled. Will teleport every 30 minutes."
else
  buffEnabled=true
fi

# Event settings
devilSquareEnabled=true    # Set to false to disable Devil Square
bloodCastleEnabled=true    # Set to false to disable Blood Castle

# Aux variables
buyPotsCounter=$initialBuyPotsCounter

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
    if [ $dsFailCount -ge $EVENT_DS_MAX_FAILS ]; then
      echo "[$(date '+%H:%M:%S')] Devil Square skipped (failed $dsFailCount times this hour)"
    else
      echo "[$(date '+%H:%M:%S')] Devil Square event time detected! (attempt $((dsFailCount + 1))/$EVENT_DS_MAX_FAILS)"
      currentTime=$(date +%s)
      timeSinceLastBuff=$((currentTime - lastBuffTime))
      buffRemaining=$((1800 - timeSinceLastBuff))
      if [ $buffRemaining -lt 720 ]; then
        echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (<12min). Buffing before event..."
        performBuffWithFallback
        lastBuffTime=$(date +%s)
      else
        echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (>=12min). Skipping buff."
      fi
      $PROJECT_DIR/bash/event/devilSquare.sh
      if [ $? -eq 0 ]; then
        ((devilSquareCount++))
      else
        ((dsFailCount++))
        echo "[$(date '+%H:%M:%S')] Devil Square failed ($dsFailCount/2 attempts this hour)"
      fi
      needToTeleportToMap=true
      continue
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
    if [ $bcFailCount -ge $EVENT_BC_MAX_FAILS ]; then
      echo "[$(date '+%H:%M:%S')] Blood Castle skipped (failed $bcFailCount times this hour)"
    else
      echo "[$(date '+%H:%M:%S')] Blood Castle event time detected! (attempt $((bcFailCount + 1))/$EVENT_BC_MAX_FAILS)"
      currentTime=$(date +%s)
      timeSinceLastBuff=$((currentTime - lastBuffTime))
      buffRemaining=$((1800 - timeSinceLastBuff))
      if [ $buffRemaining -lt 720 ]; then
        echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (<12min). Buffing before event..."
        performBuffWithFallback
        lastBuffTime=$(date +%s)
      else
        echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (>=12min). Skipping buff."
      fi
      $PROJECT_DIR/bash/event/bloodCastle.sh
      if [ $? -eq 0 ]; then
        ((bloodCastleCount++))
      else
        ((bcFailCount++))
        echo "[$(date '+%H:%M:%S')] Blood Castle failed ($bcFailCount/2 attempts this hour)"
      fi
      needToTeleportToMap=true
      continue
    fi
  fi
  # BUY POTIONS TO SURVIVE.
  # ===============================================
  if [ "$FARM_BUY_POTIONS" = true ] && [ $buyPotsCounter -eq $buyPotsCycleAt ]; then
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
  # If buff disabled, teleport to Foggy Forest every 30 minutes instead
  # ===============================================
  currentTime=$(date +%s)
  timeSinceLastBuff=$((currentTime - lastBuffTime))

  if [ "$buffEnabled" = true ]; then
    # 28 minutes = 1680 seconds, or forceBuff flag is set
    if [ $timeSinceLastBuff -gt 1680 ] || [ "$forceBuff" = true ]; then
      if [ "$forceBuff" = true ]; then
        echo "[$(date '+%H:%M:%S')] Buff forced by user..."
      else
        echo "[$(date '+%H:%M:%S')] Buff needed (last buff: $((timeSinceLastBuff / 60)) minutes ago)..."
      fi

      # Call buff function with fallback
      performBuffWithFallback
      ((buffCount++))

      # Update last buff time and reset force flag
      lastBuffTime=$(date +%s)
      needToTeleportToMap=true

      # Reset force flag
      forceBuff=false
    fi
  else
    # Buff disabled - just set teleport flag every 30 minutes (1800 seconds)
    if [ $timeSinceLastBuff -gt 1800 ]; then
      echo "[$(date '+%H:%M:%S')] 30 minutes passed. Will teleport to Foggy Forest..."
      needToTeleportToMap=true
      lastBuffTime=$(date +%s)
    fi
  fi

  # TELEPORT TO FOGGY FOREST IF NEEDED
  # ===============================================
  if [ "$needToTeleportToMap" = true ]; then
    teleportTo $LOC_FOGGY_FOREST
    # Wait at entrance if buff is disabled
    if [ "$buffEnabled" = false ]; then
      echo "[$(date '+%H:%M:%S')] Waiting 5 seconds at entrance..."
      sleep 5
    fi
  fi

  echo "[$(date '+%H:%M:%S')] New cycle $cyclesCompleted... (BuyPots: $buyPotsCounter/$buyPotsCycleAt)"

  # GO TO MOB POSITION FROM CENTER.
  # ===============================================
  sleep 1
  # Alternate between recycle+validation and game check
  $PROJECT_DIR/bash/travel/foggyForest/toMobsFromCenter.sh "satan" true &
  reposition_pid=$!

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
    echo "[$(date '+%H:%M:%S')] Game recovered. Returning to Foggy Forest..."
    teleportTo $LOC_FOGGY_FOREST
    sleep 1
    tap_equipSatan
    sleep 1
    continue
  else
    tap_auto

    # RUN AUTO SKILL FOR REMAINING BUFF TIME
    # ===============================================
    # Calculate auto skill duration
    if [ "$buffEnabled" = true ]; then
      # Buff enabled: run until buff expires (30 minutes = 1800 seconds)
      currentTime=$(date +%s)
      timeSinceLastBuff=$((currentTime - lastBuffTime))
      remainingBuffTime=$((1800 - timeSinceLastBuff))
    else
      # Buff disabled: run for fixed 30 minutes
      remainingBuffTime=1800
    fi

    echo "[$(date '+%H:%M:%S')] Arrived to mob spot. Starting auto skill for $((remainingBuffTime / 60))m $((remainingBuffTime % 60))s..."

    # Run autoPlaySkill with death detection and event time check
    # Disable event check if we already failed max attempts this hour
    checkDS=$devilSquareEnabled
    checkBC=$bloodCastleEnabled
    if [ $dsFailCount -ge $EVENT_DS_MAX_FAILS ]; then checkDS=false; fi
    if [ $bcFailCount -ge $EVENT_BC_MAX_FAILS ]; then checkBC=false; fi
    # Parameters: duration, keyCode, cooldown, checkDevilSquare, checkBloodCastle
    $PROJECT_DIR/bash/attack/autoPlaySkill.sh $remainingBuffTime 5 3 $checkDS $checkBC
    autoSkill_exit=$?

    # Handle autoPlaySkill exit codes
    if [ $autoSkill_exit -eq 2 ]; then
      # Exit code 2 = force buff (from "b" key or character died)
      if [ "$buffEnabled" = true ]; then
        echo "[$(date '+%H:%M:%S')] Forcing buff on next cycle..."
        forceBuff=true
      else
        echo "[$(date '+%H:%M:%S')] Character died. Will teleport to map on next cycle..."
        lastBuffTime=0  # This will trigger teleport check on next cycle
      fi
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
          performBuffWithFallback
          lastBuffTime=$(date +%s)
        else
          echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (>=12min). Skipping buff."
        fi
        # Skip event script - continue to top of loop where event check runs
      elif isBloodCastleTime; then
        echo "[$(date '+%H:%M:%S')] Blood Castle event time!"
        if [ $buffRemaining -lt 720 ]; then
          echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (<12min). Buffing before event..."
          performBuffWithFallback
          lastBuffTime=$(date +%s)
        else
          echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (>=12min). Skipping buff."
        fi
        # Skip event script - continue to top of loop where event check runs
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
