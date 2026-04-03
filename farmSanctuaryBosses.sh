#!/bin/bash
# FARM SANCTUARY BOSSES
# Usage: farmSanctuaryBosses.sh <level>  (1-6, default: 2)
# Travels through all 12 boss locations, fights alive bosses, skips dead ones.
# Alternates between wire 1 and wire 2 each cycle.
# Checks for Devil Square and Blood Castle events at scheduled times.
# Keys: 'p'=pause(5min), 's'=stop(15min), 'n'=skip boss, 'q'=force Devil Square, 'r'=force Blood Castle, other=abort
# ==================================================

SANCTUARY_LEVEL=${1:-2}

# Validate level
if [ "$SANCTUARY_LEVEL" -lt 1 ] || [ "$SANCTUARY_LEVEL" -gt 6 ]; then
    echo "Error: Invalid sanctuary level: $SANCTUARY_LEVEL (must be 1-6)"
    exit 1
fi

# Load configuration and utilities
source "$(dirname "$0")/config/variables.sh"
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh
source $PROJECT_DIR/config/sanctuary_bosses.sh

# Map level to location constant
case $SANCTUARY_LEVEL in
    1) SANCTUARY_LOC=$LOC_SANCTUARY_1 ;;
    2) SANCTUARY_LOC=$LOC_SANCTUARY_2 ;;
    3) SANCTUARY_LOC=$LOC_SANCTUARY_3 ;;
    4) SANCTUARY_LOC=$LOC_SANCTUARY_4 ;;
    5) SANCTUARY_LOC=$LOC_SANCTUARY_5 ;;
    6) SANCTUARY_LOC=$LOC_SANCTUARY_6 ;;
esac

PYTHON_DETECT="$PROJECT_DIR/python/detectBossStatusOnSanctuaryMap.py"
PYTHON_OPTIMIZE="$PROJECT_DIR/python/optimizeBossRouteOnSanctuaryMap.py"
WIRE_SWITCH_TIME=3  # Seconds added when using wire switch to entrance

# Handle key press: 'p' to pause, 'q' to force Devil Square, 'r' to force Blood Castle, any other key to abort
# Returns: 0=continue, 1=restart cycle (for event forcing)
handleKeyPress() {
    local key=$1
    if [ "$key" = "p" ] || [ "$key" = "P" ]; then
        echo ""
        echo "[$(date '+%H:%M:%S')] Paused. Press any key to resume..."
        read -n 1 -s
        echo "[$(date '+%H:%M:%S')] Resuming..."
        return 0  # Continue
    elif [ "$key" = "q" ] || [ "$key" = "Q" ]; then
        echo "[$(date '+%H:%M:%S')] Forcing Devil Square event on next cycle..."
        forceDevilSquare=true
        return 1  # Restart cycle
    elif [ "$key" = "r" ] || [ "$key" = "R" ]; then
        echo "[$(date '+%H:%M:%S')] Forcing Blood Castle event on next cycle..."
        forceBloodCastle=true
        return 1  # Restart cycle
    else
        echo "[$(date '+%H:%M:%S')] Aborting..."
        exit 0
    fi
}

# Statistics
startTime=$(date +%s)
bossesKilled=0
bossesSkipped=0
cycleCount=0
# Parse wire sequence from config (e.g., "1,2,3" -> array (1 2 3))
IFS=',' read -ra WIRE_SEQUENCE <<< "$SANCTUARY_WIRES"
WIRE_COUNT=${#WIRE_SEQUENCE[@]}
wireIndex=0
currentWire=1  # Assume player starts on wire 1
lastBuffTime=0
buffInterval=1620  # 27 minutes in seconds

# Potion buying settings
buyPotsCycleAt=10     # Buy potions every 10 cycles
healthPotions=2500    # Health pots to buy
manaPotions=2500      # Mana pots to buy
buyPotsCounter=0      # Current cycle counter

# Event flags
devilSquareEnabled=true   # Set to false to disable Devil Square event
bloodCastleEnabled=true   # Set to false to disable Blood Castle event
forceDevilSquare=false    # Flag to force Devil Square event on next cycle
forceBloodCastle=false    # Flag to force Blood Castle event on next cycle

# Event statistics
devilSquareCount=0
bloodCastleCount=0

# Event failure tracking (max 2 attempts per hour per event)
dsFailCount=0
bcFailCount=0
dsFailHour=-1
bcFailHour=-1

# Track if we need to return to Sanctuary (persists across continue 2)
needReturnToSanctuary=false

echo "[$(date '+%H:%M:%S')] Starting Sanctuary $SANCTUARY_LEVEL Boss Farming."
echo "[$(date '+%H:%M:%S')] Keys: 'p'=pause(5m), 's'=stop(15m), 'n'=skip, 'q'=DS, 'r'=BC, other=abort"
echo "[$(date '+%H:%M:%S')] Buff: every 28 min | Potions: every $buyPotsCycleAt cycles | Events: enabled"

# Check if buff is needed and perform it
# Returns 1 if buff was performed (need to teleport back), 0 otherwise
checkAndPerformBuff() {
    currentTime=$(date +%s)
    timeSinceLastBuff=$((currentTime - lastBuffTime))
    if [ $timeSinceLastBuff -ge $buffInterval ]; then
        echo "[$(date '+%H:%M:%S')] Buff needed (last buff: $((timeSinceLastBuff / 60)) minutes ago)..."
        performBuffFoggyForest
        buff_exit_code=$?
        if [ $buff_exit_code -eq 0 ]; then
            lastBuffTime=$(date +%s)
            return 1  # Buff performed, need to teleport back
        else
            echo "[$(date '+%H:%M:%S')] Buff skipped or failed"
        fi
    fi
    return 0  # No buff performed
}

# Get travel time from entrance to a specific boss (from config)
getTravelTimeFromEntrance() {
    local target_boss=$1
    getTravelTime "ENTRANCE" "$target_boss"
}

# Find first alive boss from status string
getFirstAliveBoss() {
    local status_string=$1
    for i in {1..12}; do
        local status=$(getBossStatus "$status_string" "$i")
        if [ "$status" = "alive" ]; then
            echo "$i"
            return
        fi
    done
    echo "0"  # No alive boss found
}

# Get all alive bosses as space-separated list
getAliveBosses() {
    local status_string=$1
    local alive_list=""
    for i in {1..12}; do
        local status=$(getBossStatus "$status_string" "$i")
        if [ "$status" = "alive" ]; then
            alive_list="$alive_list $i"
        fi
    done
    echo "$alive_list"
}

# Get travel time between any two bosses (handles reverse lookup)
getTravelTimeBetween() {
    local from_boss=$1
    local to_boss=$2

    # If same boss, no travel needed
    if [ "$from_boss" -eq "$to_boss" ]; then
        echo "0"
        return
    fi

    # Try forward lookup
    local time=$(getTravelTime "$from_boss" "$to_boss")

    # If 0, try reverse lookup (symmetric travel times)
    if [ "$time" = "0" ] || [ -z "$time" ]; then
        time=$(getTravelTime "$to_boss" "$from_boss")
    fi

    echo "$time"
}

# Get optimal route using Python optimizer
# Input: space-separated list of alive boss numbers
# Output: space-separated list with "E" markers for entrance (e.g., "1 E 7 E 5")
getOptimalRoute() {
    local alive_bosses="$1"
    python3 "$PYTHON_OPTIMIZE" "$alive_bosses"
}

# Check status of all bosses, returns comma-separated status
checkAllBossesStatus() {
    # Open map
    tap_openMap
    sleep 1

    # Take screenshot and detect
    local status=$(adb_screencap | python3 "$PYTHON_DETECT" --stdin)

    # Close map
    tap_closeMap
    sleep 0.5

    echo "$status"
}

# Check if all bosses are dead
areAllBossesDead() {
    local status=$1
    # Check if any boss is alive
    if [[ "$status" == *":alive"* ]]; then
        return 1  # Not all dead
    fi
    return 0  # All dead
}

# Get status of specific boss from status string
getBossStatus() {
    local status_string=$1
    local boss_num=$2
    # Extract status for specific boss (e.g., "3:alive" from "1:dead,2:dead,3:alive,...")
    echo "$status_string" | tr ',' '\n' | grep "^${boss_num}:" | cut -d':' -f2
}

# Get boss coordinates by name
getBossCoords() {
    local boss_name=$1
    case "$boss_name" in
        "BOSS_1")  echo "${BOSS_1[0]} ${BOSS_1[1]}" ;;
        "BOSS_2")  echo "${BOSS_2[0]} ${BOSS_2[1]}" ;;
        "BOSS_3")  echo "${BOSS_3[0]} ${BOSS_3[1]}" ;;
        "BOSS_4")  echo "${BOSS_4[0]} ${BOSS_4[1]}" ;;
        "BOSS_5")  echo "${BOSS_5[0]} ${BOSS_5[1]}" ;;
        "BOSS_6")  echo "${BOSS_6[0]} ${BOSS_6[1]}" ;;
        "BOSS_7")  echo "${BOSS_7[0]} ${BOSS_7[1]}" ;;
        "BOSS_8")  echo "${BOSS_8[0]} ${BOSS_8[1]}" ;;
        "BOSS_9")  echo "${BOSS_9[0]} ${BOSS_9[1]}" ;;
        "BOSS_10") echo "${BOSS_10[0]} ${BOSS_10[1]}" ;;
        "BOSS_11") echo "${BOSS_11[0]} ${BOSS_11[1]}" ;;
        "BOSS_12") echo "${BOSS_12[0]} ${BOSS_12[1]}" ;;
        *)         echo "0 0" ;;
    esac
}

# Navigate to boss on map and wait for travel
# Returns: 0=success, 2=location validation failed
navigateToBoss() {
    local boss_name=$1
    local travel_time=$2
    local from_location=$3

    # Get boss coordinates
    local coords=$(getBossCoords "$boss_name")
    local x=$(echo $coords | cut -d' ' -f1)
    local y=$(echo $coords | cut -d' ' -f2)

    # Open map
    tap_openMap
    sleep 0.5

    # Click boss location
    adb_tap $x $y
    sleep 0.5

    # Close map
    tap_closeMap

    echo "[$(date '+%H:%M:%S')] Traveling from $from_location to $boss_name (~${travel_time}s)..."

    # runDuringTravelling: time, recycle, validation(angel/satan/none), gameCheck, expectedLocation
    # Minimum time for full check (recycle + gameCheck + location): ~12 seconds
    # Returns: 0=success, 2=location validation failed
    local travel_exit_code=0
    if [ $travel_time -ge 15 ]; then
        runDuringTravelling $travel_time true "none" true $SANCTUARY_LOC
        travel_exit_code=$?
    else
        # Short travel - only recycle, skip game check
        runDuringTravelling $travel_time true "none" true 0
        travel_exit_code=$?
    fi

    echo "[$(date '+%H:%M:%S')] Arrived at $boss_name"
    return $travel_exit_code
}

# Main farming loop
while true; do
    ((cycleCount++))
    ((buyPotsCounter++))

    # Reset route data for new cycle
    optimalRoute=""
    previousBoss=0

    # Buy potions every X cycles
    if [ $buyPotsCounter -ge $buyPotsCycleAt ]; then
        # Read current potion counts
        currentHP=$($PROJECT_DIR/bash/utils/readNumbers.sh 792 1046 61 22) # Migrated
        currentMP=$($PROJECT_DIR/bash/utils/readNumbers.sh 891 1046 61 22) # Migrated
        echo "[$(date '+%H:%M:%S')] Current potions - HP: $currentHP, MP: $currentMP"
        echo "[$(date '+%H:%M:%S')] Buying potions ($healthPotions HP, $manaPotions MP)..."
        performBuyPotions $healthPotions $manaPotions
        buyPotsCounter=0
        needReturnToSanctuary=true
    fi

    # Cycle through wire sequence (e.g., 1,2,3 -> 1,2,3,1,2,3,...)
    targetWire=${WIRE_SEQUENCE[$wireIndex]}
    wireIndex=$(( (wireIndex + 1) % WIRE_COUNT ))

    # Switch wire if needed
    wireSwitched=false
    if [ $currentWire -ne $targetWire ]; then
        echo "[$(date '+%H:%M:%S')] Switching to wire $targetWire..."
        $PROJECT_DIR/bash/actions/switchWire.sh $targetWire
        currentWire=$targetWire
        wireSwitched=true
        sleep 3
    fi

    echo ""
    echo "========================================="
    echo "[$(date '+%H:%M:%S')] Cycle $cycleCount - Wire $currentWire"
    echo "========================================="

    # Check if buff is needed (every 28 minutes)
    checkAndPerformBuff
    buffPerformed=$?
    if [ $buffPerformed -eq 1 ]; then
        needReturnToSanctuary=true
    fi

    # CHECK FOR DEVIL SQUARE EVENT (hours 0,2,4,6 at :10-:15 OR forced by user)
    # ===============================================
    if ( [ "$devilSquareEnabled" = true ] && isDevilSquareTime ) || [ "$forceDevilSquare" = true ]; then
        # Reset fail counter if hour changed
        currentHour=$(date '+%H')
        if [ "$currentHour" != "$dsFailHour" ]; then
            dsFailCount=0
            dsFailHour=$currentHour
        fi

        if [ $dsFailCount -ge $EVENT_DS_MAX_FAILS ] && [ "$forceDevilSquare" != true ]; then
            echo "[$(date '+%H:%M:%S')] Devil Square skipped (failed $dsFailCount times this hour)"
        else
            if [ "$forceDevilSquare" = true ]; then
                echo "[$(date '+%H:%M:%S')] Devil Square event forced by user!"
            else
                echo "[$(date '+%H:%M:%S')] Devil Square event time detected!"
            fi

            # Force buff before event if it's been more than 16 minutes
            currentTime=$(date +%s)
            timeSinceLastBuff=$((currentTime - lastBuffTime))
            if [ $timeSinceLastBuff -gt 960 ]; then
                echo "[$(date '+%H:%M:%S')] Buffing before Devil Square event (last buff: $((timeSinceLastBuff / 60)) minutes ago)..."
                performBuffFoggyForest
                buff_exit_code=$?
                if [ $buff_exit_code -eq 0 ]; then
                    lastBuffTime=$(date +%s)
                fi
            fi

            # Call Devil Square script
            $PROJECT_DIR/bash/event/devilSquare.sh &
            devilsquare_pid=$!

            # Wait for Devil Square to finish, checking for key presses
            event_stopped=false
            while kill -0 $devilsquare_pid 2>/dev/null; do
                read -t 1 -n 1 key
                if [ $? = 0 ]; then
                    kill $devilsquare_pid 2>/dev/null
                    wait $devilsquare_pid 2>/dev/null
                    if [ "$key" = "s" ]; then
                        echo "[$(date '+%H:%M:%S')] Devil Square stopped by user. Waiting (15 minutes timeout)..."
                        $PROJECT_DIR/bash/actions/wait.sh 900
                        event_stopped=true
                        break
                    else
                        echo "[$(date '+%H:%M:%S')] Devil Square interrupted by user"
                        handleKeyPress "$key"
                        event_stopped=true
                        break
                    fi
                fi
            done

            wait $devilsquare_pid
            event_exit_code=$?

            if [ "$event_stopped" = false ]; then
                if [ $event_exit_code -eq 0 ]; then
                    ((devilSquareCount++))
                    echo "[$(date '+%H:%M:%S')] Devil Square completed. Total: $devilSquareCount"
                else
                    ((dsFailCount++))
                    echo "[$(date '+%H:%M:%S')] Devil Square failed ($dsFailCount/2 attempts this hour)"
                fi
            fi

            forceDevilSquare=false
            needReturnToSanctuary=true
        fi
    fi

    # CHECK FOR BLOOD CASTLE EVENT (hours 1,3,5 at :10-:15 OR forced by user)
    # ===============================================
    if ( [ "$bloodCastleEnabled" = true ] && isBloodCastleTime ) || [ "$forceBloodCastle" = true ]; then
        # Reset fail counter if hour changed
        currentHour=$(date '+%H')
        if [ "$currentHour" != "$bcFailHour" ]; then
            bcFailCount=0
            bcFailHour=$currentHour
        fi

        if [ $bcFailCount -ge $EVENT_BC_MAX_FAILS ] && [ "$forceBloodCastle" != true ]; then
            echo "[$(date '+%H:%M:%S')] Blood Castle skipped (failed $bcFailCount times this hour)"
        else
            if [ "$forceBloodCastle" = true ]; then
                echo "[$(date '+%H:%M:%S')] Blood Castle event forced by user!"
            else
                echo "[$(date '+%H:%M:%S')] Blood Castle event time detected!"
            fi

            # Force buff before event if it's been more than 16 minutes
            currentTime=$(date +%s)
            timeSinceLastBuff=$((currentTime - lastBuffTime))
            if [ $timeSinceLastBuff -gt 960 ]; then
                echo "[$(date '+%H:%M:%S')] Buffing before Blood Castle event (last buff: $((timeSinceLastBuff / 60)) minutes ago)..."
                performBuffFoggyForest
                buff_exit_code=$?
                if [ $buff_exit_code -eq 0 ]; then
                    lastBuffTime=$(date +%s)
                fi
            fi

            # Call Blood Castle script
            $PROJECT_DIR/bash/event/bloodCastle.sh &
            bloodcastle_pid=$!

            # Wait for Blood Castle to finish, checking for key presses
            event_stopped=false
            while kill -0 $bloodcastle_pid 2>/dev/null; do
                read -t 1 -n 1 key
                if [ $? = 0 ]; then
                    kill $bloodcastle_pid 2>/dev/null
                    wait $bloodcastle_pid 2>/dev/null
                    if [ "$key" = "s" ]; then
                        echo "[$(date '+%H:%M:%S')] Blood Castle stopped by user. Waiting (15 minutes timeout)..."
                        $PROJECT_DIR/bash/actions/wait.sh 900
                        event_stopped=true
                        break
                    else
                        echo "[$(date '+%H:%M:%S')] Blood Castle interrupted by user"
                        handleKeyPress "$key"
                        event_stopped=true
                        break
                    fi
                fi
            done

            wait $bloodcastle_pid
            event_exit_code=$?

            if [ "$event_stopped" = false ]; then
                if [ $event_exit_code -eq 0 ]; then
                    ((bloodCastleCount++))
                    echo "[$(date '+%H:%M:%S')] Blood Castle completed. Total: $bloodCastleCount"
                else
                    ((bcFailCount++))
                    echo "[$(date '+%H:%M:%S')] Blood Castle failed ($bcFailCount/2 attempts this hour)"
                fi
            fi

            forceBloodCastle=false
            needReturnToSanctuary=true
        fi
    fi

    # Determine if teleport is needed
    # Always teleport if we left Sanctuary $SANCTUARY_LEVEL (potions, buff, events)
    if [ "$needReturnToSanctuary" = true ]; then
        needTeleport=true
    elif [ "$wireSwitched" = true ]; then
        echo "[$(date '+%H:%M:%S')] Wire switched - already at Sanctuary $SANCTUARY_LEVEL entrance"
        needTeleport=false
    else
        currentLocation=$(getLocation)
        if [ "$currentLocation" -eq "$SANCTUARY_LOC" ]; then
            echo "[$(date '+%H:%M:%S')] Already at Sanctuary $SANCTUARY_LEVEL, skipping teleport..."
            needTeleport=false
        else
            needTeleport=true
        fi
    fi

    if [ "$needTeleport" = true ]; then
        teleportTo $SANCTUARY_LOC
        teleport_exit_code=$?

        if [ $teleport_exit_code -ne 0 ]; then
            echo "[$(date '+%H:%M:%S')] Teleport failed. Retrying in 5 seconds..."
            sleep 5
            continue
        fi

        # Teleporting to Sanctuary $SANCTUARY_LEVEL always arrives at wire 1
        currentWire=1

        # Wait for teleport to complete
        sleep 3
    fi

    # Reset flag - we're now at Sanctuary $SANCTUARY_LEVEL
    needReturnToSanctuary=false

    # Check all bosses status
    echo "[$(date '+%H:%M:%S')] Checking boss status..."
    boss_status=$(checkAllBossesStatus)

    # Get list of alive bosses
    aliveBosses=$(getAliveBosses "$boss_status")

    if [ -z "$aliveBosses" ]; then
        echo "[$(date '+%H:%M:%S')] All bosses dead this cycle. Returning to entrance..."
        $PROJECT_DIR/bash/actions/switchWire.sh $currentWire
        sleep $WIRE_SWITCH_TIME
        continue
    fi

    # echo "[$(date '+%H:%M:%S')] Alive bosses:$aliveBosses"

    # Get optimal route using Python optimizer
    optimalRoute=$(getOptimalRoute "$aliveBosses")
    echo "[$(date '+%H:%M:%S')] Optimal route: $optimalRoute"

    # Track previous boss for travel time calculation
    previousBoss=0

    # Process bosses in optimal order (route may contain "E" for entrance)
    for i in $optimalRoute; do
        # Check for entrance marker - switch wire to go to entrance
        if [ "$i" = "E" ]; then
            echo "[$(date '+%H:%M:%S')] Going to entrance (wire switch)..."
            $PROJECT_DIR/bash/actions/switchWire.sh $currentWire
            sleep $WIRE_SWITCH_TIME
            previousBoss=0
            continue
        fi

        boss_name="BOSS_$i"

        # Check if buff is needed before traveling to this boss
        checkAndPerformBuff
        buffPerformed=$?

        # If buff was performed, go back to wire 1 and do a fresh scan
        if [ $buffPerformed -eq 1 ]; then
            echo "[$(date '+%H:%M:%S')] Buff performed. Restarting cycle on wire 1 with fresh scan..."
            currentWire=1
            needReturnToSanctuary=true  # We left Sanctuary $SANCTUARY_LEVEL for buff
            # Decrement cycle count since we'll restart this cycle
            ((cycleCount--))
            continue 2  # Break out of boss loop and restart main loop
        fi

        # Calculate travel time
        if [ $previousBoss -eq 0 ]; then
            # From entrance
            travel_time=$(getTravelTimeFromEntrance "$i")
            from_location="entrance"
        else
            # From previous boss
            travel_time=$(getTravelTimeBetween "$previousBoss" "$i")
            from_location="BOSS_$previousBoss"
        fi

        navigateToBoss "$boss_name" "$travel_time" "$from_location"
        navigate_exit_code=$?

        # Check if game was closed (1) or location validation failed (2) during travel
        if [ $navigate_exit_code -eq 1 ]; then
            echo "[$(date '+%H:%M:%S')] Game was closed! Restarting cycle..."
            needReturnToSanctuary=true
            ((cycleCount--))
            continue 2  # Restart main loop
        elif [ $navigate_exit_code -eq 2 ]; then
            echo "[$(date '+%H:%M:%S')] Location validation failed! Restarting cycle..."
            needReturnToSanctuary=true
            ((cycleCount--))
            continue 2  # Restart main loop
        fi

        echo "[$(date '+%H:%M:%S')] $boss_name - Fighting..."

        # Call smartAutoPlay in background (grabTime)
        $PROJECT_DIR/bash/attack/smartAutoPlay.sh boss &
        attack_pid=$!

        # Monitor for key presses while attacking
        skippedBoss=false
        while kill -0 $attack_pid 2>/dev/null; do
            read -t 1 -n 1 key
            if [ $? = 0 ]; then
                # Key pressed - kill attack process and handle
                kill $attack_pid 2>/dev/null
                wait $attack_pid 2>/dev/null
                if [ "$key" = "n" ] || [ "$key" = "N" ]; then
                    echo "[$(date '+%H:%M:%S')] Skipping to next boss..."
                    skippedBoss=true
                    break
                elif [ "$key" = "q" ] || [ "$key" = "Q" ]; then
                    echo "[$(date '+%H:%M:%S')] Forcing Devil Square event on next cycle..."
                    forceDevilSquare=true
                    continue 3  # Restart main loop
                elif [ "$key" = "r" ] || [ "$key" = "R" ]; then
                    echo "[$(date '+%H:%M:%S')] Forcing Blood Castle event on next cycle..."
                    forceBloodCastle=true
                    continue 3  # Restart main loop
                elif [ "$key" = "p" ] || [ "$key" = "P" ]; then
                    # Tap auto attack before pausing to keep attacking
                    tap_auto
                    echo ""
                    echo "[$(date '+%H:%M:%S')] Paused. Press any key to resume (5 min timeout)..."
                    read -t 300 -n 1 -s
                    if [ $? -eq 142 ]; then
                        echo "[$(date '+%H:%M:%S')] Timeout reached. Resuming..."
                    else
                        echo "[$(date '+%H:%M:%S')] Resuming..."
                    fi
                    # Skip to next boss after pause (don't restart attack)
                    echo "[$(date '+%H:%M:%S')] Skipping to next boss..."
                    skippedBoss=true
                    break
                elif [ "$key" = "s" ] || [ "$key" = "S" ]; then
                    # Stop attacking and wait 15 minutes
                    echo ""
                    echo "[$(date '+%H:%M:%S')] Stopped. Press any key to resume (15 min timeout)..."
                    read -t 900 -n 1 -s
                    if [ $? -eq 142 ]; then
                        echo "[$(date '+%H:%M:%S')] Timeout reached. Resuming..."
                    else
                        echo "[$(date '+%H:%M:%S')] Resuming..."
                    fi
                    # Resume attacking after stop
                    $PROJECT_DIR/bash/attack/smartAutoPlay.sh boss &
                    attack_pid=$!
                else
                    handleKeyPress "$key"
                    if [ $? -eq 1 ]; then
                        continue 3  # Restart main loop for event
                    fi
                fi
            fi
        done

        # If boss was skipped, continue to next boss
        if [ "$skippedBoss" = true ]; then
            ((bossesSkipped++))
            previousBoss=$i
            continue
        fi

        wait $attack_pid
        attack_exit_code=$?

        case $attack_exit_code in
            0)
                echo "[$(date '+%H:%M:%S')] $boss_name killed!"
                ((bossesKilled++))
                ;;
            1)
                echo "[$(date '+%H:%M:%S')] Character died! Buffing and rescanning on wire $currentWire..."
                lastBuffTime=0  # Force buff
                sleep 3
                # Decrement cycle count since we'll restart this cycle
                ((cycleCount--))
                continue 2  # Restart main loop with fresh scan, keep current wire
                ;;
            2)
                echo "[$(date '+%H:%M:%S')] $boss_name was already dead"
                ((bossesSkipped++))
                ;;
            3)
                echo "[$(date '+%H:%M:%S')] $boss_name timeout"
                ((bossesSkipped++))
                ;;
        esac

        # Update previous boss for next iteration
        previousBoss=$i
    done

    # Display cycle stats
    echo ""
    echo "[$(date '+%H:%M:%S')] Cycle $cycleCount complete - Killed: $bossesKilled, Skipped: $bossesSkipped"
    echo "[$(date '+%H:%M:%S')] Starting next cycle..."
    sleep 2
done
