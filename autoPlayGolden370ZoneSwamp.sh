#!/bin/bash
# KEEP OFFENSIVE MODE AT RAKLION 3 GOLDEN SPOT
# Does active farming with wired navigation. Also, recycles items to clean inventory.
# By pressing "n" key, jumps to next wire.
# By pressing "p" key, pauses cycle.
# Other keys cancels process.
# ==================================================

recyclerCounterInit=${1:-0}     # Start cycle for recycler action. 0
targetHealthPotionsInit=${2:-$FARM_HEALTH_POTIONS}    # Target health potions
targetManaPotionsInit=${3:-$FARM_MANA_POTIONS}        # Target mana potions
smallPath=${4:-false}           # Small path doesn't relocate at center. false
avoidReposition=${5:-false}     # Avoid reposition. false

# Load configuration
source "$(dirname "$0")/config/variables.sh"

echo "Starting auto play at golden 370 zone. Press any key to cancel..."
# Constants for configuration
attackTimeA=71        # 71 normal. 43 buff & imp
autoTimeA=6           # seconds
attackTimeB=71        # 71 normal. 43 buff & imp
autoTimeB=6           # seconds
offensiveMode=true
moveMobAttacking=false
recycleCycleAt=4     # Recycle every 4 cycles
buyPotsCycleAt=150   # Buy potions every 150 cycles
repositionCycleAt=8  # Reposition every 8 cycles
repositionCounter=0
minWire=4
maxWire=5
wireToAvoid=0
pauseFlagFile="/tmp/mubot_paused"
# Aux variables
recyclerCounter=$recyclerCounterInit
buyPotsCounter=0
targetHealthPotions=$targetHealthPotionsInit
targetManaPotions=$targetManaPotionsInit
currentWire=$((minWire - 1))
forceReposition=true

# Clean up pause flag on start
rm -f "$pauseFlagFile"

while true; do
  # RECYCLE TO CLEAN INVENTORY.
  # ===============================================
  if [ $recyclerCounter -eq $recycleCycleAt ]; then
    echo "Recycling..."
    # Background execution
    $PROJECT_DIR/bash/actions/recycle.sh &
    recycle_pid=$!
    read -t 2 -n 1 key
    if [ $? = 0 ]; then
      echo "Key pressed. Aborting..."
      kill $recycle_pid 2>/dev/null
      wait $recycle_pid 2>/dev/null
      exit 0
    else
      wait $recycle_pid
    fi
    # Restart counter
    recyclerCounter=0
  fi

  # BUY POTIONS TO SURVIVE.
  # ===============================================
  if [ "$FARM_BUY_POTIONS" = true ] && [ $buyPotsCounter -eq $buyPotsCycleAt ]; then
    echo "Buying potions... [$(date '+%H:%M:%S')]"
    # Background execution
    $PROJECT_DIR/bash/actions/buyPotions.sh $targetHealthPotions $targetManaPotions &
    buyPotsPID=$!
    read -t 10 -n 1 key  # Give more time for potion buying
    if [ $? = 0 ]; then
      echo "Key pressed. Aborting..."
      kill $buyPotsPID 2>/dev/null
      wait $buyPotsPID 2>/dev/null
      exit 0
    else
      wait $buyPotsPID
    fi
    # Restart buy potions counter
    buyPotsCounter=0
    forceReposition=true
    # GO BACK TO SWAMP OF PEACE.
    # ===============================================
    $PROJECT_DIR/bash/teleport/toSwampOfPeace.sh &
    teleportPID=$!              # Save PID
    wait $teleportPID           # Wait to ensure it's terminated
    
  fi
  
  if [ "$smallPath" = false ]; then
    # Force reposition at start of each cycle
    forceReposition=true
  fi
  
  if [ "$avoidReposition" = false ] && [ $repositionCounter -eq $repositionCycleAt ]; then
    repositionCounter=0
    forceReposition=true
  fi
    
  if [ "$avoidReposition" = true ]; then
    echo "New cycle... (Recycler: $recyclerCounter/$recycleCycleAt, BuyPots: $buyPotsCounter/$buyPotsCycleAt) [$(date '+%H:%M:%S')]"
    if [ "$forceReposition" = true ]; then
      currentWire=$minWire
    fi
  else
    # Calculate current wire to switch between minWire and maxWire
    # Increment currentWire by 1, wrapping from maxWire back to minWire
    currentWire=$((currentWire + 1))
    if [ $currentWire -gt $maxWire ]; then
      currentWire=$minWire
    fi
  
    # Skip avoided wire by incrementing again if needed
    if [ $wireToAvoid -ne 0 ] && [ $currentWire -eq $wireToAvoid ]; then
      currentWire=$((currentWire + 1))
      if [ $currentWire -gt $maxWire ]; then
        currentWire=$minWire
      fi
    fi
    echo "New cycle... (Recycler: $recyclerCounter/$recycleCycleAt, BuyPots: $buyPotsCounter/$buyPotsCycleAt, Reposition: $repositionCounter/$repositionCycleAt) [$(date '+%H:%M:%S')]"
  fi
  
  # REPOSITION FROM CENTER ONLY ON START.
  # ===============================================
  if [ "$forceReposition" = true ]; then
    sleep 0.2
    $PROJECT_DIR/bash/actions/switchWire.sh $currentWire &
    switchWirePID=$!              # Save PID
    wait $switchWirePID           # Wait to ensure it's terminated
    
    # GO TO INITIAL POSITION FROM CENTER.
    # ===============================================
    sleep 1
    # Background execution
    $PROJECT_DIR/bash/travel/swamp/370zone/toTopGolden370FromCenter.sh &
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
        else
          echo "Key pressed. Aborting..."
          exit 0
        fi
      fi
    done
  elif [ "$smallPath" = true ]; then
    # MOVE TO 370 A ZONE SCRIPT (FROM 370 B ZONE ON PREVIOUS LOOP)
    # ===============================================
    sleep 1
    $PROJECT_DIR/bash/travel/swamp/370zone/toGolden370AFromB.sh &
    to370APID=$!              # Save PID
    wait $to370APID
  fi

  # RUN OFFENSIVE CYCLE SCRIPT #1
  # ===============================================
  echo "Arrived to 370 A spot... [$(date '+%H:%M:%S')]"
  totalOffensiveCycleTimeA=$((attackTimeA + autoTimeA))
  $PROJECT_DIR/bash/attack/smartAutoPlay.sh golden &
  cycle_a_pid=$!                          # Save PID
  read -t $totalOffensiveCycleTimeA -n 1 key
  if [ $? = 0 ]; then
    kill $cycle_a_pid 2>/dev/null
    wait $cycle_a_pid 2>/dev/null
    if [ "$key" = "p" ]; then
      $PROJECT_DIR/bash/actions/wait.sh
      wait_exit_code=$?
      if [ $wait_exit_code -ne 1 ]; then
        # Other than "n" aborts script
        exit 0
      fi
    elif [ "$key" = "n" ]; then
      # Just continue with traveling back
      echo " key pressed. Moving to 370 B spot..."
    else
      echo "Key pressed. Aborting..."
      exit 0
    fi
  else
    wait $cycle_a_pid                     # Wait natural ending before continue
  fi
  
  # MOVE TO 370 B ZONE SCRIPT
  # ===============================================
  sleep 1
  $PROJECT_DIR/bash/travel/swamp/370zone/toGolden370BFromA.sh &
  to370BPID=$!              # Save PID
  wait $to370BPID           # Wait to ensure it's terminated
  
  # RUN OFFENSIVE CYCLE SCRIPT #2
  # ===============================================
  echo "Arrived to 370 B spot... [$(date '+%H:%M:%S')]"
  totalOffensiveCycleTimeB=$((attackTimeB + autoTimeB))
  $PROJECT_DIR/bash/attack/smartAutoPlay.sh golden &
  cycle_b_pid=$!                          # Save PID
  read -t $totalOffensiveCycleTimeB -n 1 key
  if [ $? = 0 ]; then
    kill $cycle_b_pid 2>/dev/null
    wait $cycle_b_pid 2>/dev/null
    if [ "$key" = "p" ]; then
      $PROJECT_DIR/bash/actions/wait.sh
      wait_exit_code=$?
      if [ $wait_exit_code -ne 1 ]; then
        # Other than "+" aborts script
        exit 0
      fi
    elif [ "$key" = "n" ]; then
      # Just continue with traveling back
      echo " key pressed. Moving to 370 A spot..."
    else
      echo "Key pressed. Aborting..."
      exit 0
    fi
  else
    wait $cycle_b_pid       # Wait natural ending before continue
  fi

  forceReposition=false     # End of cycle
  ((recyclerCounter++))     # Increase recycler counter
  ((buyPotsCounter++))      # Increase buy potions counter
  ((repositionCounter++))   # Increase reposition counter
done

# Clean up pause flag on exit
rm -f "$pauseFlagFile"
