#!/bin/bash
# KEEP OFFENSIVE MODE AT Plain of four winds 410 golden
# Does active farming with wired navigation. Also, recycles items to clean inventory, but puts and go to event during nights.
# By pressing "p" key, pauses execution.
# By pressing "n" key, skips to next loop.
# Other keys cancels process.
# ==================================================

recyclerCounterInit=${1:-0}     # Start cycle for recycler action. 0

# Load configuration and utilities
source "$(dirname "$0")/config/variables.sh"
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Starting auto play at golden 400 zone. Press key to cancel..."
# Constants for configuration
recycleCycleAt=8      # Recycle every 8 cycles
buyPotsCycleAt=100    # Buy potions every 200 cycles
lifePercent=40        # Reach percent life to heal
# Wire sequence - edit this array to define the order of wires to use
wireSequence=(1 2)  # Example: cycles through wires 6,5,4
pauseFlagFile="/tmp/mubot_paused"
# Event flags
devilSquareEnabled=true    # Set to false to disable Devil Square event
bloodCastleEnabled=true    # Set to false to disable Blood Castle event
# Aux variables
recyclerCounter=$recyclerCounterInit
buyPotsCounter=0
wireIndex=0                 # Start at first element of wireSequence
lastBuffTime=0             # Track last buff time (0 = never buffed)
forceBuff=false            # Flag to force buff on next cycle

# Clean up pause flag on start
rm -f "$pauseFlagFile"

while true; do
  # RECYCLE TO CLEAN INVENTORY.
  # ===============================================
  if [ $recyclerCounter -eq $recycleCycleAt ]; then
    performSingleRecycle
    if [ $? -ne 0 ]; then
      exit 0
    fi
    # Restart counter
    recyclerCounter=0
  fi

  # BUY POTIONS TO SURVIVE.
  # ===============================================
  if [ "$FARM_BUY_POTIONS" = true ] && [ $buyPotsCounter -eq $buyPotsCycleAt ]; then
    performBuyPotions $FARM_HEALTH_POTIONS $FARM_MANA_POTIONS
    if [ $? -ne 0 ]; then
      exit 0
    fi
    
    # GO BACK TO SWAMP OF PEACE after buying potions
    $PROJECT_DIR/bash/teleport/toPlainOfFourWinds1.sh &
    teleportPID=$!
    wait $teleportPID
    
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
    performBuffDivine
    if [ $? -ne 0 ]; then
      exit 0
    fi
    
    # GO BACK TO PLAIN after buying potions
    $PROJECT_DIR/bash/teleport/toPlainOfFourWinds1.sh &
    teleportPID=$!
    wait $teleportPID

    # Update last buff time and reset force flag
    lastBuffTime=$(date +%s)
    forceBuff=false
  fi

  # CHECK FOR DEVIL SQUARE EVENT (hours 0,2,4,6 at :00-:05)
  # ===============================================
  if [ "$devilSquareEnabled" = true ] && isDevilSquareTime; then
    echo "[$(date '+%H:%M:%S')] Devil Square event time detected!"
    
    # Call Devil Square script (it will return to Union at the end)
    $PROJECT_DIR/bash/event/devilSquare.sh
    
    echo "[$(date '+%H:%M:%S')] Devil Square completed. Going back to Plan 1..."
            
    # GO BACK TO SWAMP OF PEACE after buying potions
    $PROJECT_DIR/bash/teleport/toPlainOfFourWinds1.sh &
    teleportPID=$!
    wait $teleportPID
  fi

  # CHECK FOR BLOOD CASTLE EVENT (hours 1,3,5 at :10-:15)
  # ===============================================
  if [ "$bloodCastleEnabled" = true ] && isBloodCastleTime; then
    echo "[$(date '+%H:%M:%S')] Blood Castle event time detected!"
    
    # Call Devil Square script (it will return to Union at the end)
    $PROJECT_DIR/bash/event/bloodCastle.sh
    
    echo "[$(date '+%H:%M:%S')] Blood Castle completed. Going back to Plain 1..."
            
    # GO BACK TO SWAMP OF PEACE after buying potions
    $PROJECT_DIR/bash/teleport/toPlainOfFourWinds1.sh &
    teleportPID=$!
    wait $teleportPID
  fi

  # SWITCH BETWEEN WIRES.
  # ======================
  result=$(getNextWireAndSwitch $wireIndex "${wireSequence[@]}")
  wireIndex=$(echo $result | cut -d' ' -f1)
  currentWire=$(echo $result | cut -d' ' -f2)
      
  echo "[$(date '+%H:%M:%S')] New cycle at w$currentWire... (Recycler: $recyclerCounter/$recycleCycleAt, BuyPots: $buyPotsCounter/$buyPotsCycleAt)"
    
  # GO TO INITIAL POSITION FROM CENTER.
  # ===============================================
  sleep 1
  # Background execution
  $PROJECT_DIR/bash/travel/plain1/toGolden400FromCenter.sh &
  reposition_pid=$!
  while kill -0 $reposition_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      kill $reposition_pid 2>/dev/null
      wait $reposition_pid 2>/dev/null
      if [ "$key" = "p" ]; then
        $PROJECT_DIR/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -ne 1 ]; then
          # Other than "n" aborts script
          exit 0
        fi
        continue
      elif [ "$key" = "n" ]; then
        # Skip to next parent loop
        echo "n key pressed. Skipping to next cycle..."
        ((recyclerCounter++))
        ((buyPotsCounter++))
        continue 2
      elif [ "$key" = "b" ]; then
        # Force buff on next cycle
        echo "b key pressed. Forcing buff on next cycle..."
        forceBuff=true
        ((recyclerCounter++))
        ((buyPotsCounter++))
        continue 2
      else
        echo "Key pressed. Aborting..."
        exit 0
      fi
    fi
  done

  # RUN AUTO PLAY
  # ===============================================
  echo "[$(date '+%H:%M:%S')]-Arrived to 400 spot..."
  $PROJECT_DIR/bash/attack/smartAutoPlay.sh golden &
  cycle_pid=$!                          # Save PID

  # Wait for smartAutoPlay to finish, checking for key presses
  while kill -0 $cycle_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      kill $cycle_pid 2>/dev/null
      wait $cycle_pid 2>/dev/null
      if [ "$key" = "p" ]; then
        $PROJECT_DIR/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -ne 1 ]; then
          # Other than "+" aborts script
          exit 0
        fi
        break
      elif [ "$key" = "n" ]; then
        # Just continue with traveling back
        echo " key pressed. Moving to next loop..."
        break
      elif [ "$key" = "b" ]; then
        # Force buff on next cycle
        echo "b key pressed. Forcing buff on next cycle..."
        forceBuff=true
        break
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

  ((recyclerCounter++))     # Increase recycler counter
  ((buyPotsCounter++))      # Increase buy potions counter
done

# Clean up pause flag on exit
rm -f "$pauseFlagFile"
