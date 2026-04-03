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
wireToAvoid=${5:-0}             # Wire to avoid (0 = none, 1-3 = wire number to skip)

# Load configuration
source "$(dirname "$0")/config/variables.sh"

echo "Starting auto play with wired nav. Press any key to cancel..."
# Constants for configuration
attackTime=135       # 140 seconds
autoTime=6           # 4 seconds
offensiveMode=true
moveMobAttacking=false
recycleCycleAt=5     # Recycle every 5 cycles
buyPotsCycleAt=150   # Buy potions every 150 cycles
pauseFlagFile="/tmp/mubot_paused"
# Aux variables
recyclerCounter=$recyclerCounterInit
buyPotsCounter=$buyPotsCycleAtInit
targetHealthPotions=$targetHealthPotionsInit
targetManaPotions=$targetManaPotionsInit
currentWire=0
key_action=""

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
      if [ "$key" = "n" ]; then
        echo " key pressed. Moving to next wire..."
        kill $recycle_pid 2>/dev/null
        wait $recycle_pid 2>/dev/null
        key_action="next"
        continue
      elif [ "$key" = "-" ]; then
        echo " key pressed. Moving to previous wire..."
        kill $recycle_pid 2>/dev/null
        wait $recycle_pid 2>/dev/null
        key_action="prev"
        continue
      elif [ "$key" = "p" ]; then
        kill $recycle_pid 2>/dev/null
        wait $recycle_pid 2>/dev/null
        $PROJECT_DIR/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then
          key_action="next"
        elif [ $wait_exit_code -eq 2 ]; then
          key_action="prev"
        elif [ $wait_exit_code -eq 4 ]; then
          key_action="restart"
        elif [ $wait_exit_code -eq 3 ]; then
          break
        fi
        continue
      elif [ "$key" = "r" ]; then
        echo " key pressed. Restarting at current wire..."
        kill $recycle_pid 2>/dev/null
        wait $recycle_pid 2>/dev/null
        key_action="restart"
        continue
      else
        echo "Key pressed. Aborting..."
        kill $recycle_pid 2>/dev/null
        wait $recycle_pid 2>/dev/null
        break
      fi
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
    # Background execution
    $PROJECT_DIR/bash/actions/buyPotions.sh $targetHealthPotions $targetManaPotions &
    buyPots_pid=$!
    read -t 10 -n 1 key  # Give more time for potion buying
    if [ $? = 0 ]; then
      echo "Key pressed. Aborting..."
      kill $buyPots_pid 2>/dev/null
      wait $buyPots_pid 2>/dev/null
      exit 0
    else
      wait $buyPots_pid
    fi
    # Restart buy potions counter
    buyPotsCounter=0
  
    # GO BACK TO RAKLION 3.
    # ======================
    $PROJECT_DIR/bash/teleport/toSwampOfPeace.sh $currentWire &
    teleportPID=$!              # Save PID
    wait $teleportPID           # Wait to ensure it's terminated
  fi

  # Calculate current wire to switch between 1 and 3
  if [ "$key_action" = "next" ]; then
    if [ $currentWire -eq 3 ]; then
      currentWire=1
    else
      currentWire=$((currentWire + 1))
    fi
    # Skip avoided wire
    if [ $currentWire -eq $wireToAvoid ]; then
      if [ $currentWire -eq 3 ]; then
        currentWire=1
      else
        currentWire=$((currentWire + 1))
      fi
    fi
  elif [ "$key_action" = "prev" ]; then
    if [ $currentWire -eq 1 ]; then
      currentWire=3
    else
      currentWire=$((currentWire - 1))
    fi
    # Skip avoided wire
    if [ $currentWire -eq $wireToAvoid ]; then
      if [ $currentWire -eq 1 ]; then
        currentWire=3
      else
        currentWire=$((currentWire - 1))
      fi
    fi
  elif [ "$key_action" = "restart" ]; then
    # Keep current wire, but press free respawn button in case of dead
    tap_revive_button
  else
    # Default behavior (first iteration or normal flow)
    if [ $currentWire -eq 3 ]; then
      currentWire=1
    else
      currentWire=$((currentWire + 1))
    fi
    # Skip avoided wire
    if [ $currentWire -eq $wireToAvoid ]; then
      if [ $currentWire -eq 3 ]; then
        currentWire=1
      else
        currentWire=$((currentWire + 1))
      fi
    fi
  fi

  # SWITCH BETWEEN WIRES.
  # ======================
  if [ "$key_action" != "restart" ]; then
    sleep 0.2
    $PROJECT_DIR/bash/actions/switchWire.sh $currentWire &
    switchWirePID=$!              # Save PID
    wait $switchWirePID           # Wait to ensure it's terminated
  fi

  # GO TO INITIAL POSITION.
  # ============================
  sleep 0.2
  echo "Switched to wire $currentWire... (Recycler: $recyclerCounter/$recycleCycleAt, BuyPots: $buyPotsCounter/$buyPotsCycleAt) [$(date '+%H:%M:%S')]"
  # Background execution
  $PROJECT_DIR/bash/travel/swamp/350zone/toRightGolden350FromCenter.sh &
  reposition_pid=$!
  
  while kill -0 $reposition_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      kill $reposition_pid 2>/dev/null
      wait $reposition_pid 2>/dev/null
      if [ "$key" = "n" ]; then
        echo " key pressed. Moving to next wire..."
        key_action="next"
        continue 2
      elif [ "$key" = "-" ]; then
        echo " key pressed. Moving to previous wire..."
        key_action="prev"
        continue 2
      elif [ "$key" = "p" ]; then
        $PROJECT_DIR/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then
          key_action="next"
        elif [ $wait_exit_code -eq 2 ]; then
          key_action="prev"
        elif [ $wait_exit_code -eq 4 ]; then
          key_action="restart"
        elif [ $wait_exit_code -eq 3 ]; then
          exit 0
        fi
        continue 2
      elif [ "$key" = "r" ]; then
        echo " key pressed. Restarting at current wire..."
        key_action="restart"
        continue 2
      else
        echo "Key pressed. Aborting..."
        exit 0
      fi
    fi
  done

  # RUN OFFENSIVE CYCLE SCRIPT
  # ============================
  totalOffensiveCycleTime=$((attackTime + autoTime))
  $PROJECT_DIR/bash/attack/smartAutoPlay.sh golden &
  cycle_pid=$!                          # Save PID
  read -t $totalOffensiveCycleTime -n 1 key
  if [ $? = 0 ]; then
    kill $cycle_pid 2>/dev/null
    wait $cycle_pid 2>/dev/null
    if [ "$key" = "n" ]; then
      echo " key pressed. Moving to next wire..."
      ((recyclerCounter++))                 # Increase recycler counter
      ((buyPotsCounter++))                  # Increase buy potions counter
      key_action="next"
      continue
    elif [ "$key" = "-" ]; then
      echo " key pressed. Moving to previous wire..."
      ((recyclerCounter++))                 # Increase recycler counter
      ((buyPotsCounter++))                  # Increase buy potions counter
      key_action="prev"
      continue
    elif [ "$key" = "p" ]; then
      $PROJECT_DIR/bash/actions/wait.sh
      wait_exit_code=$?
      if [ $wait_exit_code -eq 1 ]; then
        ((recyclerCounter++))
        ((buyPotsCounter++))
        key_action="next"
        continue
      elif [ $wait_exit_code -eq 2 ]; then
        ((recyclerCounter++))
        ((buyPotsCounter++))
        key_action="prev"
        continue
      elif [ $wait_exit_code -eq 4 ]; then
        key_action="restart"
        continue
      else
        # Other key - abort
        break
      fi
    elif [ "$key" = "r" ]; then
      echo " key pressed. Restarting at current wire..."
      key_action="restart"
      continue
    else
      echo "Key pressed. Aborting..."
      exit 0
    fi
  else
    wait $cycle_pid                     # Wait natural ending before continue
  fi

  key_action=""                         # Reset for next iteration
  ((recyclerCounter++))                 # Increase recycler counter
  ((buyPotsCounter++))                  # Increase buy potions counter
done

# Clean up pause flag on exit
rm -f "$pauseFlagFile"
