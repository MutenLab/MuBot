#!/bin/bash
# KEEP OFFENSIVE MODE AT Plain of four winds 410 golden
# Recycles items to clean inventory during traveling, buy pots and go to events during nights.
# By pressing "p" key, pauses execution (5 minutes timeout).
# By pressing "s" key, pauses execution (infinite wait) OR stops events (Devil Square/Blood Castle with 15 minutes timeout).
# By pressing "n" key, skips to next loop.
# By pressing "m" key, skips to next loop and forces reposition from entrance.
# By pressing "b" key, skips to next loop and forces buff.
# By pressing "q" key, skips to next loop and forces Devil Square event.
# By pressing "r" key, skips to next loop and forces Blood Castle event.
# Other keys cancels process.
# Parameters: [skipBuffOnStart=false]
# ==================================================

skipBuffOnStart=${1:-false}     # Skip buff on first run (true/false)

# Load configuration and utilities
source "$(dirname "$0")/config/variables.sh"
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh

echo "[$(date '+%H:%M:%S')] Starting auto play. Press key to cancel..."
# Constants for configuration
buyPotsCycleAt=60     # Buy potions every 60 cycles
healthPotions=$SANCTUARY_HEALTH_POTIONS
manaPotions=$SANCTUARY_MANA_POTIONS
pauseFlagFile="$MUBOT_TEMP_DIR/mubot_paused"

# Event flags
devilSquareEnabled=true   # Set to false to disable Devil Square event
bloodCastleEnabled=true    # Set to false to disable Blood Castle event
buffEnabled=true           # Set to false to disable Kanturu Relics 2 buff

# Aux variables
buyPotsCounter=0
lastCycleTime=$(date +%s)   # Used for analytics
doGameCheck=true           # Alternates between recycle+validation and game check
firstReposition=true
needsGoToMap=true

# Track last buff time - set to current time if skipping buff on start, otherwise 0
if [ "$skipBuffOnStart" = true ]; then
  lastBuffTime=$(date +%s)
  echo "[$(date '+%H:%M:%S')] Skipping buff on first run (will buff in 28 minutes)"
else
  lastBuffTime=0
fi
forceBuff=false            # Flag to force buff on next cycle
forceDevilSquare=false     # Flag to force Devil Square event on next cycle
forceBloodCastle=false     # Flag to force Blood Castle event on next cycle

# Statistics tracking
startTime=$(date +%s)
startTimeFormatted=$(date '+%d/%m %H:%M:%S')
monstersKilled=0
monstersAlreadyDead=0
monstersSkipped=0
devilSquareCount=0
bloodCastleCount=0
deathCount=0
buffCount=0
buyPotionsCount=0
cycleCount=0
shouldExit=false  # Flag to control script exit

# Function to display statistics and cleanup on exit
displayStats() {
    local endTime=$(date +%s)
    local endTimeFormatted=$(date '+%d/%m %H:%M:%S')
    local totalTime=$((endTime - startTime))
    local hours=$((totalTime / 3600))
    local minutes=$(((totalTime % 3600) / 60))
    local seconds=$((totalTime % 60))
    # Last cycle doesn't count
    ((cycleCount--))

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
    echo "             Total cycles: $cycleCount" >&2
    echo "" >&2
    echo "           Goldens killed: $monstersKilled" >&2
    echo "     Goldens already dead: $monstersAlreadyDead" >&2
    echo "          Goldens skipped: $monstersSkipped" >&2
    echo "" >&2
    echo "      Devil Square events: $devilSquareCount" >&2
    echo "      Blood Castle events: $bloodCastleCount" >&2
    echo "                   Buffed: $buffCount" >&2
    echo "             Store visits: $buyPotionsCount" >&2
    echo "" >&2
    echo "                     Died: $deathCount" >&2
    echo "=========================================" >&2
    echo "" >&2
}

# Clean up pause flag on start
rm -f "$pauseFlagFile"

while true; do
  ((cycleCount++))
  # Check if we should exit
  if [ "$shouldExit" = true ]; then
    break
  fi

  # BUY POTIONS TO SURVIVE.
  # ===============================================
  if [ "$FARM_BUY_POTIONS" = true ] && [ $buyPotsCounter -eq $buyPotsCycleAt ]; then
    performBuyPotions $healthPotions $manaPotions
    if [ $? -ne 0 ]; then
      shouldExit=true
      continue 2
    fi
    ((buyPotionsCount++))
    
    # GO BACK TO SANCTUARY 1 after buying potions
    needsGoToMap=false
    teleportTo $LOC_SANCTUARY_1

    # Restart buy potions counter
    buyPotsCounter=0
    firstReposition=true
  fi

  # CHECK FOR BUFF (every 27 minutes or if forced)
  # ===============================================
  if [ "$buffEnabled" = true ]; then
    currentTime=$(date +%s)
    timeSinceLastBuff=$((currentTime - lastBuffTime))

    # 27 minutes = 1620 seconds, or forceBuff flag is set
    if [ $timeSinceLastBuff -gt 1620 ] || [ "$forceBuff" = true ]; then
      if [ "$forceBuff" = true ]; then
        echo "[$(date '+%H:%M:%S')] Buff forced by user..."
      else
        echo "[$(date '+%H:%M:%S')] Buff needed (last buff: $((timeSinceLastBuff / 60)) minutes ago)..."
      fi

      # Call buff function
      performBuffKanturuRelics2
      buff_exit_code=$?

      # Handle exit codes from buff
      if [ $buff_exit_code -eq 10 ]; then
        # User aborted
        shouldExit=true
        continue
      elif [ $buff_exit_code -eq 5 ]; then
        # Teleport to buff location failed - skip buff and continue
        echo "[$(date '+%H:%M:%S')] Warning: Could not reach buff location. Skipping buff..."
      elif [ $buff_exit_code -eq 4 ]; then
        # User wants to force Blood Castle
        forceBloodCastle=true
      elif [ $buff_exit_code -eq 3 ]; then
        # User wants to force Devil Square
        forceDevilSquare=true
      elif [ $buff_exit_code -eq 2 ]; then
        # User wants to force buff again (keep flag)
        forceBuff=true
      elif [ $buff_exit_code -eq 1 ]; then
        # User wants to skip (continue to next cycle)
        continue
      else
        # Buff completed normally
        ((buffCount++))
        lastBuffTime=$(date +%s)
      fi

      # GO BACK TO SANCTUARY 1 after buffing
      needsGoToMap=false
      teleportTo $LOC_SANCTUARY_1
      teleport_exit_code=$?

      # Handle exit codes from teleport
      if [ $teleport_exit_code -eq 10 ]; then
        # User aborted - exit the script
        shouldExit=true
        continue
      elif [ $teleport_exit_code -eq 5 ]; then
        # Automatic retry failure - just continue, game validation will handle issues
        echo "[$(date '+%H:%M:%S')] Warning: Teleport failed after retries. Continuing anyway..."
      elif [ $teleport_exit_code -eq 4 ]; then
        forceBloodCastle=true
      elif [ $teleport_exit_code -eq 3 ]; then
        forceDevilSquare=true
      elif [ $teleport_exit_code -eq 2 ]; then
        forceBuff=true
      elif [ $teleport_exit_code -eq 1 ]; then
        continue
      fi

      # Reset force flag
      forceBuff=false
      firstReposition=true
    fi
  fi

  # CHECK FOR DEVIL SQUARE EVENT (hours 0,2,4,6 at :10-:15 OR forced by user)
  # ===============================================
  if ( [ "$devilSquareEnabled" = true ] && isDevilSquareTime ) || [ "$forceDevilSquare" = true ]; then
    if [ "$forceDevilSquare" = true ]; then
      echo "[$(date '+%H:%M:%S')] Devil Square event forced by user!"
    else
      echo "[$(date '+%H:%M:%S')] Devil Square event time detected!"
    fi

    # Force buff before event if buffing is enabled and it's been more than 16 minutes
    if [ "$buffEnabled" = true ]; then
      currentTime=$(date +%s)
      timeSinceLastBuff=$((currentTime - lastBuffTime))

      # 16 minutes = 960 seconds
      if [ $timeSinceLastBuff -gt 960 ]; then
        echo "[$(date '+%H:%M:%S')] Buffing before Devil Square event (last buff: $((timeSinceLastBuff / 60)) minutes ago)..."
        performBuffKanturuRelics2
        buff_exit_code=$?

        # Handle exit codes from buff
        if [ $buff_exit_code -eq 10 ]; then
          # User aborted
          shouldExit=true
          continue
        elif [ $buff_exit_code -eq 5 ]; then
          # Teleport to buff location failed - skip buff and continue with event
          echo "[$(date '+%H:%M:%S')] Warning: Could not reach buff location. Continuing to Devil Square without buff..."
        elif [ $buff_exit_code -eq 1 ]; then
          # User wants to skip buff, continue with event
          echo "Skipping pre-event buff, continuing to Devil Square..."
        elif [ $buff_exit_code -eq 0 ]; then
          # Buff completed normally
          ((buffCount++))
          lastBuffTime=$(date +%s)
          forceBuff=false
        fi
        # Note: exit codes 2, 3, 4 are ignored here since we're already doing what they request
      else
        echo "[$(date '+%H:%M:%S')] Buff is still fresh (buffed $((timeSinceLastBuff / 60)) minutes ago), skipping pre-event buff"
      fi
    fi

    # Call Devil Square script (it will return to Union at the end)
    $PROJECT_DIR/bash/event/devilSquare.sh &
    devilsquare_pid=$!

    # Wait for Devil Square to finish, checking for key presses
    event_stopped=false
    while kill -0 $devilsquare_pid 2>/dev/null; do
      read -t 1 -n 1 key
      if [ $? = 0 ]; then
        # Key pressed during Devil Square - kill process and handle
        kill $devilsquare_pid 2>/dev/null
        wait $devilsquare_pid 2>/dev/null
        if [ "$key" = "s" ]; then
          echo "[$(date '+%H:%M:%S')] Devil Square stopped by user. Waiting (15 minutes timeout)..."
          $PROJECT_DIR/bash/actions/wait.sh 900
          wait_exit_code=$?
          if [ $wait_exit_code -eq 10 ]; then
            shouldExit=true
          elif [ $wait_exit_code -eq 4 ]; then
            forceBloodCastle=true
          elif [ $wait_exit_code -eq 3 ]; then
            forceDevilSquare=true
          elif [ $wait_exit_code -eq 2 ]; then
            forceBuff=true
          fi
          event_stopped=true
          break
        else
          echo "[$(date '+%H:%M:%S')] Devil Square interrupted by user"
          event_stopped=true
          break
        fi
      fi
    done

    wait $devilsquare_pid 2>/dev/null

    if [ "$event_stopped" = false ]; then
      ((devilSquareCount++))
      echo "[$(date '+%H:%M:%S')] Devil Square completed. Going back to Plain 1..."
    else
      echo "[$(date '+%H:%M:%S')] Devil Square interrupted. Going back to Plain 1..."
    fi

    # GO BACK TO SANCTUARY 1 after Devil Square
    needsGoToMap=false
    teleportTo $LOC_SANCTUARY_1
    teleport_exit_code=$?

    # Handle exit codes from teleport
    if [ $teleport_exit_code -eq 10 ]; then
      # User aborted - exit the script
      shouldExit=true
      continue
    elif [ $teleport_exit_code -eq 5 ]; then
      # Automatic retry failure - just continue, game validation will handle issues
      echo "[$(date '+%H:%M:%S')] Warning: Teleport failed after retries. Continuing anyway..."
    elif [ $teleport_exit_code -eq 4 ]; then
      forceBloodCastle=true
    elif [ $teleport_exit_code -eq 3 ]; then
      forceDevilSquare=true
    elif [ $teleport_exit_code -eq 2 ]; then
      forceBuff=true
    elif [ $teleport_exit_code -eq 1 ]; then
      continue
    fi

    # Equip angel from shortcut
    sleep 1
    tap_equipAngel
    sleep 1

    # Reset force flags
    forceDevilSquare=false
    forceBloodCastle=false
    firstReposition=true
  fi

  # CHECK FOR BLOOD CASTLE EVENT (hours 1,3,5 at :10-:15 OR forced by user)
  # ===============================================
  if ( [ "$bloodCastleEnabled" = true ] && isBloodCastleTime ) || [ "$forceBloodCastle" = true ]; then
    if [ "$forceBloodCastle" = true ]; then
      echo "[$(date '+%H:%M:%S')] Blood Castle event forced by user!"
    else
      echo "[$(date '+%H:%M:%S')] Blood Castle event time detected!"
    fi

    # Force buff before event if buffing is enabled and it's been more than 16 minutes
    if [ "$buffEnabled" = true ]; then
      currentTime=$(date +%s)
      timeSinceLastBuff=$((currentTime - lastBuffTime))

      # 16 minutes = 960 seconds
      if [ $timeSinceLastBuff -gt 960 ]; then
        echo "[$(date '+%H:%M:%S')] Buffing before Blood Castle event (last buff: $((timeSinceLastBuff / 60)) minutes ago)..."
        performBuffKanturuRelics2
        buff_exit_code=$?

        # Handle exit codes from buff
        if [ $buff_exit_code -eq 10 ]; then
          # User aborted
          shouldExit=true
          continue
        elif [ $buff_exit_code -eq 5 ]; then
          # Teleport to buff location failed - skip buff and continue with event
          echo "[$(date '+%H:%M:%S')] Warning: Could not reach buff location. Continuing to Blood Castle without buff..."
        elif [ $buff_exit_code -eq 1 ]; then
          # User wants to skip buff, continue with event
          echo "Skipping pre-event buff, continuing to Blood Castle..."
        elif [ $buff_exit_code -eq 0 ]; then
          # Buff completed normally
          ((buffCount++))
          lastBuffTime=$(date +%s)
          forceBuff=false
        fi
        # Note: exit codes 2, 3, 4 are ignored here since we're already doing what they request
      else
        echo "[$(date '+%H:%M:%S')] Buff is still fresh (buffed $((timeSinceLastBuff / 60)) minutes ago), skipping pre-event buff"
      fi
    fi

    # Call Blood Castle script (it will return to Union at the end)
    $PROJECT_DIR/bash/event/bloodCastle.sh &
    bloodcastle_pid=$!

    # Wait for Blood Castle to finish, checking for key presses
    event_stopped=false
    while kill -0 $bloodcastle_pid 2>/dev/null; do
      read -t 1 -n 1 key
      if [ $? = 0 ]; then
        # Key pressed during Blood Castle - kill process and handle
        kill $bloodcastle_pid 2>/dev/null
        wait $bloodcastle_pid 2>/dev/null
        if [ "$key" = "s" ]; then
          echo "[$(date '+%H:%M:%S')] Blood Castle stopped by user. Waiting (15 minutes timeout)..."
          $PROJECT_DIR/bash/actions/wait.sh 900
          wait_exit_code=$?
          if [ $wait_exit_code -eq 10 ]; then
            shouldExit=true
          elif [ $wait_exit_code -eq 4 ]; then
            forceBloodCastle=true
          elif [ $wait_exit_code -eq 3 ]; then
            forceDevilSquare=true
          elif [ $wait_exit_code -eq 2 ]; then
            forceBuff=true
          fi
          event_stopped=true
          break
        else
          echo "[$(date '+%H:%M:%S')] Blood Castle interrupted by user"
          event_stopped=true
          break
        fi
      fi
    done

    wait $bloodcastle_pid 2>/dev/null

    if [ "$event_stopped" = false ]; then
      ((bloodCastleCount++))
      echo "[$(date '+%H:%M:%S')] Blood Castle completed. Going back to Plain 1..."
    else
      echo "[$(date '+%H:%M:%S')] Blood Castle interrupted. Going back to Plain 1..."
    fi

    # GO BACK TO SANCTUARY 1 after Blood Castle
    needsGoToMap=false
    teleportTo $LOC_SANCTUARY_1
    teleport_exit_code=$?

    # Handle exit codes from teleport
    if [ $teleport_exit_code -eq 10 ]; then
      # User aborted - exit the script
      shouldExit=true
      continue
    elif [ $teleport_exit_code -eq 5 ]; then
      # Automatic retry failure - just continue, game validation will handle issues
      echo "[$(date '+%H:%M:%S')] Warning: Teleport failed after retries. Continuing anyway..."
    elif [ $teleport_exit_code -eq 4 ]; then
      forceBloodCastle=true
    elif [ $teleport_exit_code -eq 3 ]; then
      forceDevilSquare=true
    elif [ $teleport_exit_code -eq 2 ]; then
      forceBuff=true
    elif [ $teleport_exit_code -eq 1 ]; then
      continue
    fi

    # Equip angel from shortcut
    sleep 1
    tap_equipAngel
    sleep 1

    # Reset force flags
    forceDevilSquare=false
    forceBloodCastle=false
    firstReposition=true
  fi
  
  # Calculate elapsed time since last cycle
  currentTime=$(date +%s)
  elapsed=$((currentTime - lastCycleTime))
  minutes=$((elapsed / 60))
  seconds=$((elapsed % 60))
  elapsedFormatted=$(printf "%d:%02d" $minutes $seconds)

  # Save new cycle timing
  lastCycleTime=$(date +%s)

  echo "[$(date '+%H:%M:%S')]-New cycle... (BuyPots: $buyPotsCounter/$buyPotsCycleAt) [$elapsedFormatted]"

  if [ "$needsGoToMap" = true ]; then
    teleportTo $LOC_SANCTUARY_1
      needsGoToMap=false
  fi

  # GO TO INITIAL POSITION.
  # ===============================================
  sleep 1
  # Wait for travel to finish, checking for key presses
  # Alternate between recycle+validation and game check
  if [ "$firstReposition" = true ]; then
    $PROJECT_DIR/bash/travel/sanctuary1/to440AGoldenFromEntrance2.sh "satan" "$doGameCheck" &
    reposition_pid=$!
    firstReposition=false
  else
    $PROJECT_DIR/bash/travel/sanctuary1/to440AGoldenFrom440BGolden2.sh "satan" "$doGameCheck" &
    reposition_pid=$!
  fi
  
  while kill -0 $reposition_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      # Key pressed while traveling - kill process and handle
      kill $reposition_pid 2>/dev/null
      wait $reposition_pid 2>/dev/null
      if [ "$key" = "p" ]; then # "p" pressed while traveling
        $PROJECT_DIR/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then # "n" pressed from wait
          echo "Skipping to next spot..."
        elif [ $wait_exit_code -eq 2 ]; then # "b" pressed from wait
          echo "Forcing buff on next cycle..."
          forceBuff=true
          continue 2
        elif [ $wait_exit_code -eq 3 ]; then # "q" pressed from wait
          echo "Forcing Devil Square event on next cycle..."
          forceDevilSquare=true
          continue 2
        elif [ $wait_exit_code -eq 4 ]; then # "r" pressed from wait
          echo "Forcing Blood Castle event on next cycle..."
          forceBloodCastle=true
          continue 2
        else # Other key was pressed from wait
          echo "Preparing stats..."
          shouldExit=true
          continue 2
        fi
      elif [ "$key" = "s" ]; then # "s" pressed while traveling (infinite wait)
        $PROJECT_DIR/bash/actions/wait.sh 0
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then # "n" pressed from wait
          echo "Skipping to next spot..."
        elif [ $wait_exit_code -eq 2 ]; then # "b" pressed from wait
          echo "Forcing buff on next cycle..."
          forceBuff=true
          continue 2
        elif [ $wait_exit_code -eq 3 ]; then # "q" pressed from wait
          echo "Forcing Devil Square event on next cycle..."
          forceDevilSquare=true
          continue 2
        elif [ $wait_exit_code -eq 4 ]; then # "r" pressed from wait
          echo "Forcing Blood Castle event on next cycle..."
          forceBloodCastle=true
          continue 2
        else # Other key was pressed from wait
          echo "Preparing stats..."
          shouldExit=true
          continue 2
        fi
      elif [ "$key" = "n" ]; then # "n" pressed while traveling
        # Skip to next parent loop
        echo " key pressed. Skipping to next spot..."
      elif [ "$key" = "m" ]; then # "m" pressed while traveling
        # Skip to next parent loop and force reposition
        echo " key pressed. Skipping and forcing reposition..."
        firstReposition=true
      elif [ "$key" = "b" ]; then # "b" pressed while traveling
        # Force buff on next cycle
        echo " key pressed. Forcing buff on next loop..."
        forceBuff=true
        continue 2
      elif [ "$key" = "q" ]; then # "q" pressed while traveling
        # Force Devil Square event on next cycle
        echo " key pressed. Forcing Devil Square event on next loop..."
        forceDevilSquare=true
        continue 2
      elif [ "$key" = "r" ]; then # "r" pressed while traveling
        # Force Blood Castle event on next cycle
        echo " key pressed. Forcing Blood Castle event on next loop..."
        forceBloodCastle=true
        continue 2
      else
        echo " key pressed. Aborting..."
        shouldExit=true
        continue 2
      fi
    fi
  done

  wait $reposition_pid
  travel_exit_code=$?

  # Check if game or location validation failed during travel
  if [ $travel_exit_code -eq 1 ]; then
    sleep 5
    echo "[$(date '+%H:%M:%S')] Game recovered. Returning to Sanctuary 1..."
    teleportTo $LOC_SANCTUARY_1
    sleep 1
    # Equip angel from shortcut
    tap_equipAngel
    sleep 1
    firstReposition=true
    needsGoToMap=false
    continue
  elif [ $travel_exit_code -eq 2 ]; then
    echo "[$(date '+%H:%M:%S')] Wrong location detected (likely killed). Returning to Sanctuary 1..."
    ((deathCount++))
    forceBuff=true
    firstReposition=true
    needsGoToMap=true
    continue
  fi

  # RUN AUTO PLAY AT ZONE A
  # ===============================================
  echo "[$(date '+%H:%M:%S')] Arrived to 440A Golden spot..."
  $PROJECT_DIR/bash/attack/smartAutoPlay.sh golden &
  cycle_pid=$!                          # Save PID

  # Wait for AutoPlay to finish, checking for key presses
  while kill -0 $cycle_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      # Key pressed while autoPlay - kill process and handle
      kill $cycle_pid 2>/dev/null
      wait $cycle_pid 2>/dev/null

      if [ "$key" = "p" ]; then # "p" pressed while autoplay
        $PROJECT_DIR/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then # n pressed from wait
          echo "Skipping to next spot..."
          ((monstersKilled++))
        elif [ $wait_exit_code -eq 2 ]; then # b pressed from wait
          echo "Forcing buff on next cycle..."
          forceBuff=true
          ((monstersKilled++))
          continue 2
        elif [ $wait_exit_code -eq 3 ]; then # q pressed from wait
          echo "Forcing Devil Square event on next cycle..."
          forceDevilSquare=true
          ((monstersKilled++))
          continue 2
        elif [ $wait_exit_code -eq 4 ]; then # r pressed from wait
          echo "Forcing Blood Castle event on next cycle..."
          forceBloodCastle=true
          ((monstersKilled++))
          continue 2
        else # Other than "n" aborts script
          echo "Preparing stats..."
          shouldExit=true
          continue 2
        fi
      elif [ "$key" = "s" ]; then # "s" pressed while autoplay (infinite wait)
        $PROJECT_DIR/bash/actions/wait.sh 0
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then # n pressed from wait
          echo "Skipping to next spot..."
          ((monstersKilled++))
        elif [ $wait_exit_code -eq 2 ]; then # b pressed from wait
          echo "Forcing buff on next cycle..."
          forceBuff=true
          ((monstersKilled++))
          continue 2
        elif [ $wait_exit_code -eq 3 ]; then # q pressed from wait
          echo "Forcing Devil Square event on next cycle..."
          forceDevilSquare=true
          ((monstersKilled++))
          continue 2
        elif [ $wait_exit_code -eq 4 ]; then # r pressed from wait
          echo "Forcing Blood Castle event on next cycle..."
          forceBloodCastle=true
          ((monstersKilled++))
          continue 2
        else # Other than "n" aborts script
          echo "Preparing stats..."
          shouldExit=true
          continue 2
        fi
      elif [ "$key" = "n" ]; then # "n" pressed while autoplay
        # Skip to next parent loop
        echo " key pressed. Moving to next spot..."
        ((monsterSkipped++))
      elif [ "$key" = "m" ]; then # "m" pressed while autoplay
        # Skip to next parent loop and force reposition
        echo " key pressed. Moving and forcing reposition..."
        ((monsterSkipped++))
        firstReposition=true
        needsGoToMap=true
      elif [ "$key" = "b" ]; then
        # Force buff on next cycle
        echo " key pressed. Forcing buff on next loop..."
        forceBuff=true
        ((monsterSkipped++))
        continue 2
      elif [ "$key" = "q" ]; then
        # Force Devil Square event on next cycle
        echo " key pressed. Forcing Devil Square event on next loop..."
        forceDevilSquare=true
        ((monsterSkipped++))
        continue 2
      elif [ "$key" = "r" ]; then
        # Force Blood Castle event on next cycle
        echo " key pressed. Forcing Blood Castle event on next loop..."
        forceBloodCastle=true
        ((monsterSkipped++))
        continue 2
      else
        echo " key pressed. Aborting..."
        shouldExit=true
        continue 2
      fi
    fi
  done

  wait $cycle_pid
  cycle_exit_code=$?

  # Track monster kills (only count valid cycles, not already dead)
  if [ $cycle_exit_code -eq 0 ]; then # Monster killed
    ((monstersKilled++))
  elif [ $cycle_exit_code -eq 1 ]; then # Character died
    ((monsterSkipped++))
    ((deathCount++))
    forceBuff=true
    firstReposition=true
    needsGoToMap=true
  elif [ $cycle_exit_code -eq 2 ]; then # Monster already dead
    ((monstersAlreadyDead++))
  elif [ $cycle_exit_code -eq 3 ]; then # Timeout
    ((monsterSkipped++))
  fi

  # GO TO 440B FROM 440A.
  # ===============================================
  sleep 1
  # Wait for travel to finish, checking for key presses
  # Alternate between recycle+validation and game check
  $PROJECT_DIR/bash/travel/sanctuary1/to440BGoldenFrom440AGolden2.sh "satan" "$doGameCheck" &
  reposition_pid=$!
  while kill -0 $reposition_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      # Key pressed while traveling - kill process and handle
      kill $reposition_pid 2>/dev/null
      wait $reposition_pid 2>/dev/null
      if [ "$key" = "p" ]; then # "p" pressed while traveling
        $PROJECT_DIR/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then # "n" pressed from wait
          echo "Skipping to next spot..."
        elif [ $wait_exit_code -eq 2 ]; then # "b" pressed from wait
          echo "Forcing buff on next cycle..."
          forceBuff=true
          continue 2
        elif [ $wait_exit_code -eq 3 ]; then # "q" pressed from wait
          echo "Forcing Devil Square event on next cycle..."
          forceDevilSquare=true
          continue 2
        elif [ $wait_exit_code -eq 4 ]; then # "r" pressed from wait
          echo "Forcing Blood Castle event on next cycle..."
          forceBloodCastle=true
          continue 2
        else # Other key was pressed from wait
          echo "Preparing stats..."
          shouldExit=true
          continue 2
        fi
      elif [ "$key" = "s" ]; then # "s" pressed while traveling (infinite wait)
        $PROJECT_DIR/bash/actions/wait.sh 0
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then # "n" pressed from wait
          echo "Skipping to next spot..."
        elif [ $wait_exit_code -eq 2 ]; then # "b" pressed from wait
          echo "Forcing buff on next cycle..."
          forceBuff=true
          continue 2
        elif [ $wait_exit_code -eq 3 ]; then # "q" pressed from wait
          echo "Forcing Devil Square event on next cycle..."
          forceDevilSquare=true
          continue 2
        elif [ $wait_exit_code -eq 4 ]; then # "r" pressed from wait
          echo "Forcing Blood Castle event on next cycle..."
          forceBloodCastle=true
          continue 2
        else # Other key was pressed from wait
          echo "Preparing stats..."
          shouldExit=true
          continue 2
        fi
      elif [ "$key" = "n" ]; then # "n" pressed while traveling
        # Skip to next parent loop
        echo " key pressed. Skipping to next spot..."
      elif [ "$key" = "m" ]; then # "m" pressed while traveling
        # Skip to next parent loop and force reposition
        echo " key pressed. Skipping and forcing reposition..."
        firstReposition=true
        needsGoToMap=true
      elif [ "$key" = "b" ]; then # "b" pressed while traveling
        # Force buff on next cycle
        echo " key pressed. Forcing buff on next loop..."
        forceBuff=true
        continue 2
      elif [ "$key" = "q" ]; then # "q" pressed while traveling
        # Force Devil Square event on next cycle
        echo " key pressed. Forcing Devil Square event on next loop..."
        forceDevilSquare=true
        continue 2
      elif [ "$key" = "r" ]; then # "r" pressed while traveling
        # Force Blood Castle event on next cycle
        echo " key pressed. Forcing Blood Castle event on next loop..."
        forceBloodCastle=true
        continue 2
      else
        echo " key pressed. Aborting..."
        shouldExit=true
        continue 2
      fi
    fi
  done

  wait $reposition_pid
  travel_exit_code=$?

  # Check if game or location validation failed during travel
  if [ $travel_exit_code -eq 1 ]; then
    sleep 5
    echo "[$(date '+%H:%M:%S')] Game recovered. Returning to Sanctuary 1..."
    teleportTo $LOC_SANCTUARY_1
    sleep 1
    # Equip angel from shortcut
    tap_equipAngel
    sleep 1
    firstReposition=true
    needsGoToMap=false
    continue
  elif [ $travel_exit_code -eq 2 ]; then
    echo "[$(date '+%H:%M:%S')] Wrong location detected (likely killed). Returning to Sanctuary 1..."
    ((deathCount++))
    forceBuff=true
    firstReposition=true
    needsGoToMap=true
    continue
  fi

  # RUN AUTO PLAY AT ZONE B
  # ===============================================
  echo "[$(date '+%H:%M:%S')] Arrived to 440A Golden spot..."
  $PROJECT_DIR/bash/attack/smartAutoPlay.sh golden &
  cycle_pid=$!                          # Save PID

  # Wait for AutoPlay to finish, checking for key presses
  while kill -0 $cycle_pid 2>/dev/null; do
    read -t 1 -n 1 key
    if [ $? = 0 ]; then
      # Key pressed while autoPlay - kill process and handle
      kill $cycle_pid 2>/dev/null
      wait $cycle_pid 2>/dev/null

      if [ "$key" = "p" ]; then # "p" pressed while autoplay
        $PROJECT_DIR/bash/actions/wait.sh
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then # n pressed from wait
          echo "Skipping to next spot..."
          ((monstersKilled++))
        elif [ $wait_exit_code -eq 2 ]; then # b pressed from wait
          echo "Forcing buff on next cycle..."
          forceBuff=true
          ((monstersKilled++))
          continue 2
        elif [ $wait_exit_code -eq 3 ]; then # q pressed from wait
          echo "Forcing Devil Square event on next cycle..."
          forceDevilSquare=true
          ((monstersKilled++))
          continue 2
        elif [ $wait_exit_code -eq 4 ]; then # r pressed from wait
          echo "Forcing Blood Castle event on next cycle..."
          forceBloodCastle=true
          ((monstersKilled++))
          continue 2
        else # Other than "n" aborts script
          echo "Preparing stats..."
          shouldExit=true
          continue 2
        fi
      elif [ "$key" = "s" ]; then # "s" pressed while autoplay (infinite wait)
        $PROJECT_DIR/bash/actions/wait.sh 0
        wait_exit_code=$?
        if [ $wait_exit_code -eq 1 ]; then # n pressed from wait
          echo "Skipping to next spot..."
          ((monstersKilled++))
        elif [ $wait_exit_code -eq 2 ]; then # b pressed from wait
          echo "Forcing buff on next cycle..."
          forceBuff=true
          ((monstersKilled++))
          continue 2
        elif [ $wait_exit_code -eq 3 ]; then # q pressed from wait
          echo "Forcing Devil Square event on next cycle..."
          forceDevilSquare=true
          ((monstersKilled++))
          continue 2
        elif [ $wait_exit_code -eq 4 ]; then # r pressed from wait
          echo "Forcing Blood Castle event on next cycle..."
          forceBloodCastle=true
          ((monstersKilled++))
          continue 2
        else # Other than "n" aborts script
          echo "Preparing stats..."
          shouldExit=true
          continue 2
        fi
      elif [ "$key" = "n" ]; then # "n" pressed while autoplay
        # Skip to next parent loop
        echo " key pressed. Moving to next spot..."
        ((monsterSkipped++))
      elif [ "$key" = "m" ]; then # "m" pressed while autoplay
        # Skip to next parent loop and force reposition
        echo " key pressed. Moving and forcing reposition..."
        ((monsterSkipped++))
        firstReposition=true
        needsGoToMap=true
      elif [ "$key" = "b" ]; then
        # Force buff on next cycle
        echo " key pressed. Forcing buff on next loop..."
        forceBuff=true
        ((monsterSkipped++))
        continue 2
      elif [ "$key" = "q" ]; then
        # Force Devil Square event on next cycle
        echo " key pressed. Forcing Devil Square event on next loop..."
        forceDevilSquare=true
        ((monsterSkipped++))
        continue 2
      elif [ "$key" = "r" ]; then
        # Force Blood Castle event on next cycle
        echo " key pressed. Forcing Blood Castle event on next loop..."
        forceBloodCastle=true
        ((monsterSkipped++))
        continue 2
      else
        echo " key pressed. Aborting..."
        shouldExit=true
        continue 2
      fi
    fi
  done

  wait $cycle_pid
  cycle_exit_code=$?

  # Track monster kills (only count valid cycles, not already dead)
  if [ $cycle_exit_code -eq 0 ]; then # Monster killed
    ((buyPotsCounter++))
    ((monstersKilled++))
  elif [ $cycle_exit_code -eq 1 ]; then # Character died
    ((buyPotsCounter++))
    ((monsterSkipped++))
    ((deathCount++))
    forceBuff=true
    firstReposition=true
    needsGoToMap=true
  elif [ $cycle_exit_code -eq 2 ]; then # Monster already dead
    ((buyPotsCounter++))
    ((monstersAlreadyDead++))
  elif [ $cycle_exit_code -eq 3 ]; then # Timeout
    ((monsterSkipped++))
  fi

done

# Display statistics before exiting
displayStats
