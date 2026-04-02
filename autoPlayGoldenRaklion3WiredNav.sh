#!/bin/bash
# KEEP OFFENSIVE MODE AT RAKLION 3 GOLDEN SPOT
# Does active farming with wired navigation. Also, recycles items to clean inventory, buy pots and go to events.
# By pressing "p" key, pauses execution.
# By pressing "n" key, jumps to next wire.
# By pressing "b" key, forces buff on next cycle.
# Other keys cancels process.
# Parameters: [recyclerCounterInit=0] [buyPotsCycleAtInit=0] [skipBuffOnStart=false]
# ==================================================

buyPotsCycleAtInit=${1:-0}       # Start cycle for buy potions action. 0
skipBuffOnStart=${2:-false}      # Skip buff on first run (true/false)

# Load configuration and utilities
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/farmingUtils.sh
source /Users/icerrate/AndroidStudioProjects/bot/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Starting auto play at Raklion 3 golden zone. Press key to cancel..."
# Constants for configuration
buyPotsCycleAt=200       # Buy potions every 200 cycles
healthPotions=3000       # Health pots to buy
manaPotions=3000         # Mana pots to buy
# Wire sequence - edit this array to define the order of wires to use
wireSequence=(1 2 3)     # Cycles through wires 1, 2, 3
pauseFlagFile="/tmp/mubot_paused"

# Event flags
devilSquareEnabled=false    # Set to false to disable Devil Square event
bloodCastleEnabled=false    # Set to false to disable Blood Castle event
buffEnabled=false           # Set to false to disable Divine buff

# Aux variables
recyclerCounter=$recyclerCounterInit
buyPotsCounter=$buyPotsCycleAtInit
gameCheckCounter=0          # Counter for game closed check
wireIndex=0                 # Start at first element of wireSequence
lastCycleTime=$(date +%s)   # Used for analytics
key_action=""               # Track key-based actions (next/prev/restart)

# Track last buff time - set to current time if skipping buff on start, otherwise 0
if [ "$skipBuffOnStart" = true ]; then
  lastBuffTime=$(date +%s)
  echo "[$(date '+%H:%M:%S')] Skipping buff on first run (will buff in 28 minutes)"
else
  lastBuffTime=0
fi
forceBuff=false            # Flag to force buff on next cycle

# Clean up pause flag on start
rm -f "$pauseFlagFile"

while true; do

  # BUY POTIONS TO SURVIVE.
  # ===============================================
  if [ $buyPotsCounter -eq $buyPotsCycleAt ]; then
    performBuyPotions $healthPotions $manaPotions
    if [ $? -ne 0 ]; then
      exit 0
    fi

    # GO BACK TO RAKLION 3 after buying potions
    /Users/icerrate/AndroidStudioProjects/bot/bash/teleport/toRaklion3.sh &
    teleportPID=$!
    wait $teleportPID

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
      if [ $? -ne 0 ]; then
        exit 0
      fi

      # GO BACK TO RAKLION 3 after buffing
      /Users/icerrate/AndroidStudioProjects/bot/bash/teleport/toRaklion3.sh &
      teleportPID=$!
      wait $teleportPID

      # Update last buff time and reset force flag
      lastBuffTime=$(date +%s)
      forceBuff=false
    fi
  fi

  # CHECK FOR DEVIL SQUARE EVENT (hours 0,2,4,6 at :10-:15)
  # ===============================================
  if [ "$devilSquareEnabled" = true ] && isDevilSquareTime; then
    echo "[$(date '+%H:%M:%S')] Devil Square event time detected!"

    # Force buff before event if buffing is enabled and it's been more than 16 minutes
    if [ "$buffEnabled" = true ]; then
      currentTime=$(date +%s)
      timeSinceLastBuff=$((currentTime - lastBuffTime))

      # 16 minutes = 960 seconds
      if [ $timeSinceLastBuff -gt 960 ]; then
        echo "[$(date '+%H:%M:%S')] Buffing before Devil Square event (last buff: $((timeSinceLastBuff / 60)) minutes ago)..."
        performBuffKanturuRelics2
        if [ $? -ne 0 ]; then
          exit 0
        fi

        # Update last buff time
        lastBuffTime=$(date +%s)
        forceBuff=false
      else
        echo "[$(date '+%H:%M:%S')] Buff is still fresh (buffed $((timeSinceLastBuff / 60)) minutes ago), skipping pre-event buff"
      fi
    fi

    # Call Devil Square script (it will return to Union at the end)
    /Users/icerrate/AndroidStudioProjects/bot/bash/event/devilSquare.sh

    echo "[$(date '+%H:%M:%S')] Devil Square completed. Going back to Raklion 3..."

    # GO BACK TO RAKLION 3 after event
    /Users/icerrate/AndroidStudioProjects/bot/bash/teleport/toRaklion3.sh &
    teleportPID=$!
    wait $teleportPID
  fi

  # CHECK FOR BLOOD CASTLE EVENT (hours 1,3,5 at :10-:15)
  # ===============================================
  if [ "$bloodCastleEnabled" = true ] && isBloodCastleTime; then
    echo "[$(date '+%H:%M:%S')] Blood Castle event time detected!"

    # Force buff before event if buffing is enabled and it's been more than 16 minutes
    if [ "$buffEnabled" = true ]; then
      currentTime=$(date +%s)
      timeSinceLastBuff=$((currentTime - lastBuffTime))

      # 16 minutes = 960 seconds
      if [ $timeSinceLastBuff -gt 960 ]; then
        echo "[$(date '+%H:%M:%S')] Buffing before Blood Castle event (last buff: $((timeSinceLastBuff / 60)) minutes ago)..."
        performBuffKanturuRelics2
        if [ $? -ne 0 ]; then
          exit 0
        fi

        # Update last buff time
        lastBuffTime=$(date +%s)
        forceBuff=false
      else
        echo "[$(date '+%H:%M:%S')] Buff is still fresh (buffed $((timeSinceLastBuff / 60)) minutes ago), skipping pre-event buff"
      fi
    fi

    # Call Blood Castle script (it will return to Union at the end)
    /Users/icerrate/AndroidStudioProjects/bot/bash/event/bloodCastle.sh

    echo "[$(date '+%H:%M:%S')] Blood Castle completed. Going back to Raklion 3..."

    # GO BACK TO RAKLION 3 after event
    /Users/icerrate/AndroidStudioProjects/bot/bash/teleport/toRaklion3.sh &
    teleportPID=$!
    wait $teleportPID
  fi

    # SWITCH BETWEEN WIRES.
  # ======================
  result=$(getNextWireAndSwitch $wireIndex "${wireSequence[@]}")
  wireIndex=$(echo $result | cut -d' ' -f1)
  currentWire=$(echo $result | cut -d' ' -f2)
  
  # Calculate elapsed time since last cycle
  currentTime=$(date +%s)
  elapsed=$((currentTime - lastCycleTime))
  minutes=$((elapsed / 60))
  seconds=$((elapsed % 60))
  elapsedFormatted=$(printf "%d:%02d" $minutes $seconds)

  # Save new cycle timing
  lastCycleTime=$(date +%s)

  echo "[$(date '+%H:%M:%S')] New cycle at w$currentWire... (BuyPots: $buyPotsCounter/$buyPotsCycleAt) [$elapsedFormatted]"
  
  # GO TO INITIAL POSITION FROM CENTER.
  # ===============================================
  sleep 1
  # Background execution without potion validation
  /Users/icerrate/AndroidStudioProjects/bot/bash/travel/raklion3/toGoldenSpot.sh "none" &
  reposition_pid=$!
  while kill -0 $reposition_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      kill $reposition_pid 2>/dev/null
      wait $reposition_pid 2>/dev/null
      if [ "$key" = "p" ]; then
        /Users/icerrate/AndroidStudioProjects/bot/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -eq 5 ]; then
          # "b" key pressed in wait.sh - force buff
          echo "Forcing buff on next cycle..."
          forceBuff=true
          ((buyPotsCounter++))
          continue 2
        elif [ $wait_exit_code -ne 1 ]; then
          # Other than "n" aborts script
          exit 0
        fi
        continue
      elif [ "$key" = "n" ]; then
        # Skip to next parent loop
        echo "n key pressed. Skipping to next loop..."
        ((buyPotsCounter++))
        continue 2
      elif [ "$key" = "b" ]; then
        # Force buff on next cycle
        echo "b key pressed. Forcing buff on next loop..."
        forceBuff=true
        ((buyPotsCounter++))
        continue 2
      else
        echo "Key pressed. Aborting..."
        exit 0
      fi
    fi
  done

  wait $reposition_pid

  # RUN  AUTO PLAY
  # ===============================================
  echo "[$(date '+%H:%M:%S')]-Arrived to 410 spot..."
  /Users/icerrate/AndroidStudioProjects/bot/bash/attack/smartAutoPlay.sh 4 golden &
  cycle_pid=$!                          # Save PID

  # Wait for smartAutoPlay to finish, checking for key presses
  while kill -0 $cycle_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      kill $cycle_pid 2>/dev/null
      wait $cycle_pid 2>/dev/null
      if [ "$key" = "p" ]; then
        /Users/icerrate/AndroidStudioProjects/bot/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -eq 5 ]; then
          # "b" key pressed in wait.sh - force buff
          echo "Forcing buff on next cycle..."
          forceBuff=true
          break
        elif [ $wait_exit_code -ne 1 ]; then
          # Other than "n" aborts script
          exit 0
        fi
        break
      elif [ "$key" = "n" ]; then
        # Just continue with traveling back
        echo " key pressed. Moving to next loop..."
        break
      elif [ "$key" = "b" ]; then
        # Force buff on next cycle
        echo "b key pressed. Forcing buff on next loop..."
        forceBuff=true
        continue 2
      else
        echo "Key pressed. Aborting..."
        exit 0
      fi
    fi
  done

  # Wait for natural ending if not interrupted
  wait $cycle_pid 2>/dev/null
  
  # Press revive button zone in case of dead to speed up resume sequence
  tap_revive_button
  # sleep 0.5

  ((buyPotsCounter++))      # Increase buy potions counter
done

# Clean up pause flag on exit
rm -f "$pauseFlagFile"
