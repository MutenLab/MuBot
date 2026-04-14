#!/bin/bash
# FARM SANCTUARY BOSSES (IMPROVED)
# Sanctuary level is read from local.properties (sanctuary.level)
# Travels through all 12 boss locations, fights alive bosses, skips dead ones.
# Rotates wires per local.properties (sanctuary.wires).
# Checks for Devil Square and Blood Castle events at scheduled times:
#   - At the top of every cycle (before teleport/buff/boss loop).
#   - Before every boss iteration (mid-wire guard), so an event window that
#     opens while clearing a wire is caught on the next boss iteration instead
#     of waiting for the whole wire to finish.
# After an event, we always teleport back to Sanctuary (lands on wire 1) and
# re-switch to the wire that was in progress — wireIndex is advanced only at
# the end of a fully-executed cycle so events do not consume a wire slot.
# Keys: 'p'=pause(5min), 's'=stop(15min), 'n'=skip boss, 'q'=force Devil Square, 'r'=force Blood Castle, other=abort
# ==================================================

# Load configuration and utilities
source "$(dirname "$0")/config/variables.sh"

# Validate level
if [ "$SANCTUARY_LEVEL" -lt 1 ] || [ "$SANCTUARY_LEVEL" -gt 6 ]; then
    echo "Error: Invalid sanctuary level: $SANCTUARY_LEVEL (must be 1-6)"
    exit 1
fi
source $PROJECT_DIR/bash/utils/farmingUtils.sh
source $PROJECT_DIR/bash/utils/eventUtils.sh
source $PROJECT_DIR/config/sanctuary_bosses.sh

SANCTUARY_LOC=$LOC_SANCTUARY

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
bossesKilled=0
bossesSkipped=0
# Parse wire sequence from config (e.g., "1,2,3" -> array (1 2 3))
IFS=',' read -ra WIRE_SEQUENCE <<< "$SANCTUARY_WIRES"
WIRE_COUNT=${#WIRE_SEQUENCE[@]}
wireIndex=0
currentWire=1  # Assume player starts on wire 1
lastBuffTime=0
buffInterval=1620  # 27 minutes in seconds

# Potion buying settings
buyPotsCycleAt=10     # Buy potions every 10 cycles
healthPotions=$SANCTUARY_HEALTH_POTIONS
manaPotions=$SANCTUARY_MANA_POTIONS
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
    local start="$1"
    local alive_bosses="$2"
    python3 "$PYTHON_OPTIMIZE" "$start" "$alive_bosses"
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

    return $travel_exit_code
}

# Main farming loop
while true; do
    ((buyPotsCounter++))

    # Buy potions every X cycles
    if [ "$FARM_BUY_POTIONS" = true ] && [ $buyPotsCounter -ge $buyPotsCycleAt ]; then
        # Read current potion counts
        currentHP=$($PROJECT_DIR/bash/utils/readNumbers.sh 792 1046 61 22) # Migrated
        currentMP=$($PROJECT_DIR/bash/utils/readNumbers.sh 891 1046 61 22) # Migrated
        [[ ${#currentMP} -gt 4 ]] && currentMP=${currentMP: -4}
        echo "[$(date '+%H:%M:%S')] Current potions - HP: $currentHP, MP: $currentMP"
        echo "[$(date '+%H:%M:%S')] Buying potions ($healthPotions HP, $manaPotions MP)..."
        performBuyPotions $healthPotions $manaPotions
        buyPotsCounter=0
        needReturnToSanctuary=true
    fi

    # Cycle through wire sequence (e.g., 1,2,3 -> 1,2,3,1,2,3,...).
    # wireIndex is advanced at the END of the cycle (after the boss loop),
    # so an event `continue` leaves the same targetWire picked on the next
    # iteration — the interrupted wire resumes with a fresh scan.
    targetWire=${WIRE_SEQUENCE[$wireIndex]}

    echo ""
    echo "========================================="
    echo "[$(date '+%H:%M:%S')] Cycle $buyPotsCounter/$buyPotsCycleAt - Target wire $targetWire"
    echo "========================================="

    # Check if buff is needed (every 28 minutes)
    checkAndPerformBuff
    buffPerformed=$?
    if [ $buffPerformed -eq 1 ]; then
        needReturnToSanctuary=true
    fi

    # CHECK FOR DEVIL SQUARE EVENT
    # ===============================================
    if ( [ "$devilSquareEnabled" = true ] && isDevilSquareTime ) || [ "$forceDevilSquare" = true ]; then
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
                echo "[$(date '+%H:%M:%S')] Devil Square event time detected! (attempt $((dsFailCount + 1))/$EVENT_DS_MAX_FAILS)"
            fi

            currentTime=$(date +%s)
            timeSinceLastBuff=$((currentTime - lastBuffTime))
            buffRemaining=$((1800 - timeSinceLastBuff))
            if [ $buffRemaining -lt 720 ]; then
                echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (<12min). Buffing before event..."
                performBuffFoggyForest
                buff_exit_code=$?
                if [ $buff_exit_code -eq 0 ]; then
                    lastBuffTime=$(date +%s)
                fi
            else
                echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (>=12min). Skipping buff."
            fi

            $PROJECT_DIR/bash/event/devilSquare.sh
            if [ $? -eq 0 ]; then
                ((devilSquareCount++))
                echo "[$(date '+%H:%M:%S')] Devil Square completed. Total: $devilSquareCount"
            else
                ((dsFailCount++))
                echo "[$(date '+%H:%M:%S')] Devil Square failed ($dsFailCount/$EVENT_DS_MAX_FAILS attempts this hour)"
            fi

            forceDevilSquare=false
            needReturnToSanctuary=true
            continue
        fi
    fi

    # CHECK FOR BLOOD CASTLE EVENT
    # ===============================================
    if ( [ "$bloodCastleEnabled" = true ] && isBloodCastleTime ) || [ "$forceBloodCastle" = true ]; then
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
                echo "[$(date '+%H:%M:%S')] Blood Castle event time detected! (attempt $((bcFailCount + 1))/$EVENT_BC_MAX_FAILS)"
            fi

            currentTime=$(date +%s)
            timeSinceLastBuff=$((currentTime - lastBuffTime))
            buffRemaining=$((1800 - timeSinceLastBuff))
            if [ $buffRemaining -lt 720 ]; then
                echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (<12min). Buffing before event..."
                performBuffFoggyForest
                buff_exit_code=$?
                if [ $buff_exit_code -eq 0 ]; then
                    lastBuffTime=$(date +%s)
                fi
            else
                echo "[$(date '+%H:%M:%S')] Buff remaining: ${buffRemaining}s (>=12min). Skipping buff."
            fi

            $PROJECT_DIR/bash/event/bloodCastle.sh
            if [ $? -eq 0 ]; then
                ((bloodCastleCount++))
                echo "[$(date '+%H:%M:%S')] Blood Castle completed. Total: $bloodCastleCount"
            else
                ((bcFailCount++))
                echo "[$(date '+%H:%M:%S')] Blood Castle failed ($bcFailCount/$EVENT_BC_MAX_FAILS attempts this hour)"
            fi

            forceBloodCastle=false
            needReturnToSanctuary=true
            continue
        fi
    fi

    # Determine if teleport is needed
    # Always teleport if we left Sanctuary $SANCTUARY_LEVEL (potions, buff, events)
    if [ "$needReturnToSanctuary" = true ]; then
        needTeleport=true
    else
        currentLocation=$(getLocation)
        if [ "$currentLocation" -eq "$LOC_SANCTUARY" ]; then
            echo "[$(date '+%H:%M:%S')] Already at Sanctuary, skipping teleport..."
            needTeleport=false
        else
            needTeleport=true
        fi
    fi

    if [ "$needTeleport" = true ]; then
        teleportTo $SANCTUARY_LOC $SANCTUARY_LEVEL
        teleport_exit_code=$?

        if [ $teleport_exit_code -ne 0 ]; then
            echo "[$(date '+%H:%M:%S')] Teleport failed. Retrying in 5 seconds..."
            sleep 5
            continue
        fi

        # Teleporting to Sanctuary always arrives at wire 1
        currentWire=1

        # Wait for teleport to complete
        sleep 3
    fi

    # Reset flag - we're now at Sanctuary $SANCTUARY_LEVEL
    needReturnToSanctuary=false

    # Switch to target wire if needed (must be after teleport since teleport resets to wire 1)
    if [ $currentWire -ne $targetWire ]; then
        echo "[$(date '+%H:%M:%S')] Switching to wire $targetWire..."
        $PROJECT_DIR/bash/actions/switchWire.sh $targetWire
        currentWire=$targetWire
        sleep 3
    fi

    # Track current position for route optimization (E=entrance, or boss number)
    currentPosition="E"

    # Process bosses by scanning and re-routing after each fight
    while true; do
        # Event guard — runs at the top of every iteration so any outcome from
        # the previous boss (killed, skipped, paused, already-dead, timeout)
        # still checks the event window. Placed before the map scan to skip
        # that cost on exit. On hit: `continue 2` returns to the main loop,
        # where the top-of-cycle DS/BC block fires; `needReturnToSanctuary=true`
        # forces the post-event teleport, and targetWire stays the same so the
        # interrupted wire is resumed after the event.
        if ( [ "$devilSquareEnabled" = true ] && isDevilSquareTime ) \
           || ( [ "$bloodCastleEnabled" = true ] && isBloodCastleTime ); then
            echo "[$(date '+%H:%M:%S')] Event window detected mid-wire. Returning to main cycle..."
            needReturnToSanctuary=true
            continue 2
        fi

        # Scan boss status and compute route from current position
        echo "[$(date '+%H:%M:%S')] Checking boss status..."
        boss_status=$(checkAllBossesStatus)
        aliveBosses=$(getAliveBosses "$boss_status")

        if [ -z "$aliveBosses" ]; then
            echo "[$(date '+%H:%M:%S')] All bosses dead this cycle."
            break
        fi

        optimalRoute=$(getOptimalRoute "$currentPosition" "$aliveBosses")
        echo "[$(date '+%H:%M:%S')] Route from $currentPosition: $optimalRoute"

        # Get only the first target (with optional E prefix)
        nextIsEntrance=false
        targetBoss=""
        for i in $optimalRoute; do
            if [ "$i" = "E" ]; then
                nextIsEntrance=true
                continue
            fi
            targetBoss=$i
            break
        done

        if [ -z "$targetBoss" ]; then
            break
        fi

        # Go to entrance first if needed
        if [ "$nextIsEntrance" = true ]; then
            echo "[$(date '+%H:%M:%S')] Going to entrance (wire switch)..."
            $PROJECT_DIR/bash/actions/switchWire.sh $currentWire
            sleep $WIRE_SWITCH_TIME
            currentPosition="E"
        fi

        i=$targetBoss
        previousBoss=0
        if [ "$currentPosition" != "E" ]; then
            previousBoss=$currentPosition
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
            continue 2  # Restart main loop
        elif [ $navigate_exit_code -eq 2 ]; then
            echo "[$(date '+%H:%M:%S')] Location validation failed! Restarting cycle..."
            needReturnToSanctuary=true
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

        # If boss was skipped, update position and re-scan
        if [ "$skippedBoss" = true ]; then
            ((bossesSkipped++))
            currentPosition=$i
            continue
        fi

        wait $attack_pid
        attack_exit_code=$?

        case $attack_exit_code in
            0)
                ((bossesKilled++))
                currentPosition=$i
                ;;
            1)
                echo "[$(date '+%H:%M:%S')] Character died! Buffing and rescanning on wire $currentWire..."
                lastBuffTime=0  # Force buff
                sleep 3
                continue 2  # Restart main loop with fresh scan, keep current wire
                ;;
            2)
                echo "[$(date '+%H:%M:%S')] $boss_name was already dead"
                ((bossesSkipped++))
                currentPosition=$i
                ;;
            3)
                echo "[$(date '+%H:%M:%S')] $boss_name timeout"
                ((bossesSkipped++))
                currentPosition=$i
                ;;
        esac

    done

    # Advance wire rotation only after a cycle fully completed its boss loop.
    # Event `continue`s earlier in the cycle skip this line, so the same wire
    # is picked again on the next iteration and resumed post-event.
    wireIndex=$(( (wireIndex + 1) % WIRE_COUNT ))

    # Display cycle stats
    echo ""
    echo "[$(date '+%H:%M:%S')] Cycle $buyPotsCounter/$buyPotsCycleAt complete - Killed: $bossesKilled, Skipped: $bossesSkipped"
    echo "[$(date '+%H:%M:%S')] Starting next cycle..."
    sleep 2
done
