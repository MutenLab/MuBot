#!/bin/bash
# KEEP OFFENSIVE MODE AT RAKLION 3 GOLDEN SPOT
# Does active farming with wired navigation. Also, recycles items to clean inventory.
# By pressing "n" key, jumps to next wire.
# By pressing "-" key, jumps to previous wire.
# Other keys cancels process.
# ==================================================

recyclerCounterInit=${1:-0}     # Start cycle for recycler action. 0
buyPotsCycleAtInit=${2:-0}      # Start cycle for buy potions action. 0
targetHealthPotionsInit=${3:-3465}    # Target health potions. 3465
targetManaPotionsInit=${4:-1980}      # Target mana potions. 1980

# Load configuration
source "$(dirname "$0")/config/variables.sh"

echo "Starting auto play at golden 350-360 zone. Press any key to cancel..."
# Constants for configuration
attackTimeA=90        # 94. 86 with imp
autoTimeA=6           # seconds
attackTimeB=90        # 94. 86 with imp
autoTimeB=6           # seconds
offensiveMode=true
moveMobAttacking=false
recycleCycleAt=2     # Recycle every 5 cycles
buyPotsCycleAt=50   # Buy potions every 150 cycles
pauseFlagFile="/tmp/mubot_paused"
# Aux variables
recyclerCounter=$recyclerCounterInit
buyPotsCounter=$buyPotsCycleAtInit
targetHealthPotions=$targetHealthPotionsInit
targetManaPotions=$targetManaPotionsInit
key_action="start"

# Clean up pause flag on start
rm -f "$pauseFlagFile"

while true; do
  # RECYCLE TO CLEAN INVENTORY.
  # ============================
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
  # ========================
  if [ $buyPotsCounter -eq $buyPotsCycleAt ]; then
    echo "Buying potions..."
    key_action="start"
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
  
    # GO BACK TO SWAMP OF PEACE.
    # ======================
    $PROJECT_DIR/bash/teleport/toSwampOfPeace.sh $currentWire &
    teleportPID=$!              # Save PID
    wait $teleportPID           # Wait to ensure it's terminated
    
  fi
  

  # SWITCH BETWEEN WIRES.
  # ======================
  if [ "$key_action" = "start" ]; then
    sleep 0.2
    $PROJECT_DIR/bash/actions/switchWire.sh 2 &
    switchWirePID=$!              # Save PID
    wait $switchWirePID           # Wait to ensure it's terminated
  fi
  
  # GO TO INITIAL POSITION FROM CENTER.
  # ============================
  sleep 1
  if [ "$key_action" = "start" ]; then
    echo "Moving to 350 zone..."
    # Background execution
    $PROJECT_DIR/bash/travel/swamp/350zone/toRightGolden350FromCenter.sh &
    reposition_pid=$!
    while kill -0 $reposition_pid 2>/dev/null; do
      read -t 1 -n 1 key
      if [ $? = 0 ]; then
          kill $reposition_pid 2>/dev/null
          wait $reposition_pid 2>/dev/null
        if [ "$key" = "p" ]; then
          $PROJECT_DIR/bash/actions/wait.sh
          wait_exit_code=$?
          if [ $wait_exit_code -eq 1 ]; then
            key_action="next"
          elif [ $wait_exit_code -eq 3 ]; then
            exit 0
          fi
          continue
        else
          echo "Key pressed. Aborting..."
          exit 0
        fi
      fi
    done
  else
    echo "New cycle... (Recycler: $recyclerCounter/$recycleCycleAt, BuyPots: $buyPotsCounter/$buyPotsCycleAt) [$(date '+%H:%M:%S')]"
  fi

  # RUN OFFENSIVE CYCLE SCRIPT #1
  # ============================
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
      if [ $wait_exit_code -eq 1 ]; then
        # Just continue with traveling back
        key_action="next"
      else
        exit 0
      fi
    elif [ "$key" = "n" ]; then
      # Just continue with traveling back
      echo " key pressed. Moving to 360 spot..."
      key_action="next"
    else
      echo "Key pressed. Aborting..."
      exit 0
    fi
  else
    wait $cycle_a_pid                     # Wait natural ending before continue
  fi
  
  # MOVE TO 360 ZONE SCRIPT
  sleep 1
  $PROJECT_DIR/bash/travel/swamp/360zone/toGolden360From350.sh &
  to360PID=$!              # Save PID
  wait $to360PID           # Wait to ensure it's terminated
  
  # RUN OFFENSIVE CYCLE SCRIPT #2
  # ============================
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
      if [ $wait_exit_code -eq 1 ]; then
        # Just continue with traveling back
        key_action="next"
      else
        exit 0
      fi
    elif [ "$key" = "n" ]; then
      # Just continue with traveling back
      echo " key pressed. Moving to 350 spot..."
      key_action="next"
    else
      echo "Key pressed. Aborting..."
      exit 0
    fi
  else
    wait $cycle_b_pid                     # Wait natural ending before continue
  fi
      
  # MOVE BACK TO 350 ZONE SCRIPT
  sleep 1
  $PROJECT_DIR/bash/travel/swamp/360zone/toGolden350From360.sh &
  to350PID=$!              # Save PID
  wait $to350PID           # Wait to ensure it's terminated

  key_action="restart"                  # Reset for next iteration
  ((recyclerCounter++))                 # Increase recycler counter
  ((buyPotsCounter++))                  # Increase buy potions counter
done

# Clean up pause flag on exit
rm -f "$pauseFlagFile"
