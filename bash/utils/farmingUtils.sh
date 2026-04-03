#!/bin/bash
# FARMING UTILITIES
# Common functions used across farming scripts
# ==================================================

source $PROJECT_DIR/bash/utils/visionUtils.sh

# Check if a specific app is running (process exists)
# Parameters: $1 = package name (e.g., "com.tszz.gpen")
# Returns: 0 if app process is running, 1 if not running
isAppRunning() {
    local packageName=${1:-"$GAME_PACKAGE"}

    # Check if the app process exists using pidof (adb_shell uses correct device)
    local pid=$(adb_shell pidof "$packageName" 2>/dev/null | tr -d '\r')

    if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ ]]; then
        return 0  # App is running
    else
        return 1  # App is not running
    fi
}

# Check if a specific app is in the foreground (currently visible)
# Parameters: $1 = package name (e.g., "com.tszz.gpen")
# Returns: 0 if app is in foreground, 1 if not
isAppInForeground() {
    local packageName=${1:-"$GAME_PACKAGE"}

    # Get the current foreground activity (adb_shell uses correct device)
    local currentActivity=$(adb_shell dumpsys activity activities 2>/dev/null | grep -E 'topResumedActivity|mResumedActivity' | head -1)

    if [[ "$currentActivity" == *"$packageName"* ]]; then
        return 0  # App is in foreground
    else
        return 1  # App is not in foreground
    fi
}

# Function to handle recycling with user interruption support
# Returns 0 if successful, 1 if user aborted
performSingleRecycle() {
    if [ "$recycleEnable" = true ]; then
        # echo "[$(date '+%H:%M:%S')] Recycling while traveling..."
        # Background execution
        $PROJECT_DIR/bash/actions/recycle.sh &
        recycle_pid=$!
        read -t 2 -n 1 key
        if [ $? = 0 ]; then
            echo "Key pressed. Aborting..."
            kill $recycle_pid 2>/dev/null
            wait $recycle_pid 2>/dev/null
            return 1
        else
            wait $recycle_pid
        fi
    fi
    return 0
}

# Function to handle buying potions with user interruption support
# Detect and close expired popup (e.g. "Jewel Boost Card has expired")
# Checks if popup is visible, taps close, verifies it closed. Retries if needed.
detectAndCloseExpiredPopup() {
    if isExpiredPopupVisible; then
        echo "[$(date '+%H:%M:%S')] Expired popup detected. Closing..."
        tap_close_expired_pop_up
        sleep 1
        # Verify popup is closed
        if isExpiredPopupVisible; then
            echo "[$(date '+%H:%M:%S')] Popup still visible. Retrying..."
            tap_close_expired_pop_up
            sleep 1
        fi
        echo "[$(date '+%H:%M:%S')] Expired popup closed."
    fi
}

# Returns 0 if successful, 1 if user aborted
# Parameters: $1 = TARGET_HEALTH_POTIONS (default: 2200), $2 = TARGET_MANA_POTIONS (default: 1800)
performBuyPotions() {
    local targetHealthPotions=${1:-2200}
    local targetManaPotions=${2:-1800}

    # Teleport to Lorencia first to avoid cooldown/attack effects blocking OCR
    echo "[$(date '+%H:%M:%S')] Teleporting to Lorencia to read potions safely..."
    $PROJECT_DIR/bash/teleport/toLorencia.sh

    echo "[$(date '+%H:%M:%S')] Running Buying potions block..."
    # Background execution
    $PROJECT_DIR/bash/actions/buyPotions.sh $targetHealthPotions $targetManaPotions &
    buyPotsPID=$!
    read -t 10 -n 1 key  # Give more time for potion buying
    if [ $? = 0 ]; then
        echo "Key pressed. Aborting..."
        kill $buyPotsPID 2>/dev/null
        wait $buyPotsPID 2>/dev/null
        return 1
    else
        wait $buyPotsPID
    fi
    
    return 0
}

# Function to get next wire from sequence and switch to it
# Parameters: $1 = current wireIndex, followed by wireSequence array elements
# Returns: "wireIndex currentWire" for the caller to capture
getNextWireAndSwitch() {
    local idx=$1
    shift  # Remove first argument (index)
    local wireSeq=("$@")  # Remaining arguments are the array elements
    
    # Get the current wire from the array
    local currentWire=${wireSeq[$idx]}
    
    # Increment index for next iteration
    idx=$((idx + 1))
    
    # Wrap around to start if we've reached the end of the array
    if [ $idx -ge ${#wireSeq[@]} ]; then
        idx=0
    fi
    
    # Switch to the selected wire
    sleep 0.2
    $PROJECT_DIR/bash/actions/switchWire.sh $currentWire &
    local switchWirePID=$!
    wait $switchWirePID
    
    # Return both the new index and current wire number
    echo "$idx $currentWire"
}

# Function to handle Divine buff with user interruption support
# Returns 0 if successful, 1 if user aborted
performBuffKanturuRelics2() {
    echo "[$(date '+%H:%M:%S')] Looking for buff at Kanturu Relics 2 (Bot)..."

    # Call teleportTo
    teleportTo $LOC_KANTURU_RELICS_2
    local teleport_exit_code=$?
    if [ $teleport_exit_code -ne 0 ]; then
        return $teleport_exit_code
    fi

    # Switch wire in background with key monitoring
    $PROJECT_DIR/bash/actions/switchWire.sh 1 &
    switchWirePID=$!
    while kill -0 $switchWirePID 2>/dev/null; do
        read -t 1 -n 1 key
        if [ $? = 0 ]; then
            kill $switchWirePID 2>/dev/null
            wait $switchWirePID 2>/dev/null
            if [ "$key" = "p" ]; then
                $PROJECT_DIR/bash/actions/wait.sh
                wait_exit_code=$?
                if [ $wait_exit_code -ne 1 ]; then
                    return 1
                fi
                # Continue after unpause
            elif [ "$key" = "n" ]; then
                echo " key pressed. Skipping buff..."
                return 0
            else
                echo " key pressed. Aborting buff..."
                return 1
            fi
        fi
    done
    wait $switchWirePID

    # Move to spot in background with key monitoring
    $PROJECT_DIR/bash/travel/kanturuRelics2/toBuffSpotBot.sh &
    travelPID=$!
    while kill -0 $travelPID 2>/dev/null; do
        read -t 1 -n 1 key
        if [ $? = 0 ]; then
            kill $travelPID 2>/dev/null
            wait $travelPID 2>/dev/null
            if [ "$key" = "p" ]; then
                $PROJECT_DIR/bash/actions/wait.sh
                wait_exit_code=$?
                if [ $wait_exit_code -ne 1 ]; then
                    return 1
                fi
                # Continue after unpause
            elif [ "$key" = "n" ]; then
                echo " key pressed. Skipping buff..."
                return 0
            else
                echo " key pressed. Aborting buff..."
                return 1
            fi
        fi
    done
    wait $travelPID

    # Give time to elf to buff character (7*6 seconds with buff checking and key monitoring)
    elapsed=0
    while [ $elapsed -lt 7 ]; do
        read -t 1 -n 1 key
        if [ $? = 0 ]; then
            if [ "$key" = "p" ]; then
                $PROJECT_DIR/bash/actions/wait.sh
                wait_exit_code=$?
                if [ $wait_exit_code -ne 1 ]; then
                    return 1
                fi
            elif [ "$key" = "n" ]; then
                echo " key pressed. Skipping buff..."
                return 0
            else
                echo " key pressed. Aborting buff..."
                return 1
            fi
        else
            ((elapsed++))
            # Check for buffs every second
            checkBuff
            if [ $? -eq 0 ]; then
                echo "[$(date '+%H:%M:%S')] Buffs detected early at ${elapsed}s"
                return 0
            fi
        fi
    done

    echo "[$(date '+%H:%M:%S')] Buff timeout reached"
    return 0
}

performBuffFoggyForest() {
    local maxRetries=3
    local attempt=1

    while [ $attempt -le $maxRetries ]; do
        echo "[$(date '+%H:%M:%S')] Looking for buff at Foggy Forest (attempt $attempt/$maxRetries)..."

        # Move to buff spot in background with key monitoring
        $PROJECT_DIR/bash/actions/goToFoggyForestBuffSpot.sh &
        travelPID=$!
        while kill -0 $travelPID 2>/dev/null; do
            read -t 1 -n 1 key
            if [ $? = 0 ]; then
                kill $travelPID 2>/dev/null
                wait $travelPID 2>/dev/null
                if [ "$key" = "p" ]; then
                    $PROJECT_DIR/bash/actions/wait.sh
                    wait_exit_code=$?
                    if [ $wait_exit_code -ne 1 ]; then
                        return 1
                    fi
                    # Continue after unpause
                elif [ "$key" = "n" ]; then
                    echo " key pressed. Skipping buff..."
                    return 0
                else
                    echo " key pressed. Aborting buff..."
                    return 1
                fi
            fi
        done
        wait $travelPID

        # Give time to elf to buff character (7 seconds with buff checking and key monitoring)
        elapsed=0
        while [ $elapsed -lt 7 ]; do
            read -t 1 -n 1 key
            if [ $? = 0 ]; then
                if [ "$key" = "p" ]; then
                    $PROJECT_DIR/bash/actions/wait.sh
                    wait_exit_code=$?
                    if [ $wait_exit_code -ne 1 ]; then
                        return 1
                    fi
                elif [ "$key" = "n" ]; then
                    echo " key pressed. Skipping buff..."
                    return 0
                else
                    echo " key pressed. Aborting buff..."
                    return 1
                fi
            else
                ((elapsed++))
                # Check for buffs every second
                checkBuff
                if [ $? -eq 0 ]; then
                    echo "[$(date '+%H:%M:%S')] Buffs detected early at ${elapsed}s"
                    return 0
                fi
            fi
        done

        echo "[$(date '+%H:%M:%S')] Buff timeout reached (attempt $attempt/$maxRetries)"
        ((attempt++))
    done

    echo "[$(date '+%H:%M:%S')] Buff failed after $maxRetries attempts"
    return 2
}

performBuffLandOfDemons() {
    echo "[$(date '+%H:%M:%S')] Looking for buff at Land of Demons..."

    # Call teleportTo
    teleportTo $LOC_LAND_OF_DEMONS
    local teleport_exit_code=$?
    if [ $teleport_exit_code -ne 0 ]; then
        return $teleport_exit_code
    fi

    # Switch wire in background with key monitoring
    $PROJECT_DIR/bash/actions/switchWire.sh 1 &
    switchWirePID=$!
    while kill -0 $switchWirePID 2>/dev/null; do
        read -t 1 -n 1 key
        if [ $? = 0 ]; then
            kill $switchWirePID 2>/dev/null
            wait $switchWirePID 2>/dev/null
            if [ "$key" = "p" ]; then
                $PROJECT_DIR/bash/actions/wait.sh
                wait_exit_code=$?
                if [ $wait_exit_code -ne 1 ]; then
                    return 1
                fi
                # Continue after unpause
            elif [ "$key" = "n" ]; then
                echo " key pressed. Skipping buff..."
                return 0
            else
                echo " key pressed. Aborting buff..."
                return 1
            fi
        fi
    done
    wait $switchWirePID

    # Move to buff spot in background with key monitoring
    $PROJECT_DIR/bash/travel/landOfDemons/toBuffSpotBot.sh &
    travelPID=$!
    while kill -0 $travelPID 2>/dev/null; do
        read -t 1 -n 1 key
        if [ $? = 0 ]; then
            kill $travelPID 2>/dev/null
            wait $travelPID 2>/dev/null
            if [ "$key" = "p" ]; then
                $PROJECT_DIR/bash/actions/wait.sh
                wait_exit_code=$?
                if [ $wait_exit_code -ne 1 ]; then
                    return 1
                fi
                # Continue after unpause
            elif [ "$key" = "n" ]; then
                echo " key pressed. Skipping buff..."
                return 0
            else
                echo " key pressed. Aborting buff..."
                return 1
            fi
        fi
    done
    wait $travelPID

    # Give time to elf to buff character (7 seconds with buff checking and key monitoring)
    elapsed=0
    while [ $elapsed -lt 7 ]; do
        read -t 1 -n 1 key
        if [ $? = 0 ]; then
            if [ "$key" = "p" ]; then
                $PROJECT_DIR/bash/actions/wait.sh
                wait_exit_code=$?
                if [ $wait_exit_code -ne 1 ]; then
                    return 1
                fi
            elif [ "$key" = "n" ]; then
                echo " key pressed. Skipping buff..."
                return 0
            else
                echo " key pressed. Aborting buff..."
                return 1
            fi
        else
            ((elapsed++))
            # Check for buffs every second
            checkBuff
            if [ $? -eq 0 ]; then
                echo "[$(date '+%H:%M:%S')] Buffs detected early at ${elapsed}s"
                return 0
            fi
        fi
    done

    echo "[$(date '+%H:%M:%S')] Buff timeout reached"
    return 2  # Return 2 to indicate timeout (no buff detected)
}

# Perform buff with fallback strategy
# First tries Land of Demons, if no buff detected after timeout, falls back to Kanturu Relics 2
# Returns: 0 always (continues regardless of result)
performBuffWithFallback() {
    # Try primary buff location
    performBuffFoggyForest
    local primary_exit=$?

    # Exit code 0 = buff detected, 1 = aborted, 2 = timeout (no buff)
    if [ $primary_exit -eq 0 ]; then
        # Buff confirmed from Land of Demons
        return 0
    elif [ $primary_exit -eq 1 ]; then
        # User aborted, don't try fallback
        return 0
    fi

    # Timeout (exit code 2) - try fallback
    echo "[$(date '+%H:%M:%S')] No buff detected, trying Kanturu Relics 2 as fallback..."
    performBuffKanturuRelics2

    return 0
}

validateSatanImp() {
    # Reference image path
    REFERENCE_IMAGE="$PROJECT_DIR/img/${satanImpType}.png"

    # Inventory slot coordinates for satan item
    X=792 # Migrated
    Y=175 # Migrated
    WIDTH=55 # Migrated
    HEIGHT=55 # Migrated

    # echo "[$(date '+%H:%M:%S')] Checking Satan item in inventory..."

    # Open inventory
    tap_open_inventory
    sleep 1

    # Check if satan item is present
    result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$REFERENCE_IMAGE")

    if [[ "$result" == "similar" ]]; then
        # echo "[$(date '+%H:%M:%S')] Satan already equipped"
        # Close inventory
        tap_inventory_close
        sleep 1
    else
        # echo "[$(date '+%H:%M:%S')] Satan not found. Equipping..."
        # Close inventory
        tap_inventory_close
        sleep 1
        # Equip satan from shortcut
        tap_equipSatan
        sleep 1
    fi
}

validateAngelImp() {
    # Reference image path
    REFERENCE_IMAGE="$PROJECT_DIR/img/angel.png"

    # Inventory slot coordinates for angel item
    X=792 # Migrated
    Y=175 # Migrated
    WIDTH=55 # Migrated
    HEIGHT=55 # Migrated

    # echo "[$(date '+%H:%M:%S')] Checking Angel item in inventory..."

    # Open inventory
    tap_open_inventory
    sleep 1

    # Check if satan item is present
    result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$REFERENCE_IMAGE")

    if [[ "$result" == "similar" ]]; then
        # echo "[$(date '+%H:%M:%S')] Angel already equipped"
        # Close inventory
        tap_inventory_close
    else
        # echo "[$(date '+%H:%M:%S')] Angel not found. Equipping..."
        # Close inventory
        tap_inventory_close
        sleep 1
        # Equip angel from shortcut
        tap_equipAngel
    fi
}

validateCharacterIsDead() {
    # Reference image path
    REFERENCE_IMAGE="$PROJECT_DIR/img/dead_title.png"

    # Dead title coordinates
    X=664 # Migrated
    Y=363 # Migrated
    WIDTH=580 # Migrated
    HEIGHT=37 # Migrated

    # Check if dead title is present
    result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$REFERENCE_IMAGE")

    if [[ "$result" == "similar" ]]; then
        # Revive
        tap_revive_button
        return 0  # Dead
    else
        return 1  # Alive
    fi
}

checkBuff() {
    # Reference image paths
    local ATTACK_BUFF="$PROJECT_DIR/img/attack_buff.png"
    local SHIELD_BUFF="$PROJECT_DIR/img/shield_buff.png"
    local COMPARE_SCRIPT="$PROJECT_DIR/python/compareImages.py"
    local THRESHOLD=80

    # Scan positions: buffs can shift depending on other status icons
    local ZONE_Y=1036 # Migrated
    local WIDTH=30 # Migrated
    local HEIGHT=30 # Migrated
    local SCAN_POSITIONS="1484 1527 1567 1610" # Migrated

    # Take ONE screenshot to avoid animation differences between comparisons
    local TEMP_SS=$(mktemp /tmp/mubot_buff_XXXXXX.png)
    adb_screencap > "$TEMP_SS"

    local attack_found=false
    local shield_found=false

    # Scan all positions for both buffs
    for zone_x in $SCAN_POSITIONS; do
        if [ "$attack_found" = false ]; then
            local sim=$(magick "$TEMP_SS" -crop ${WIDTH}x${HEIGHT}+${zone_x}+${ZONE_Y} png:- | python3 "$COMPARE_SCRIPT" "$ATTACK_BUFF" --stdin 2>/dev/null)
            if (( $(echo "${sim:-0} >= $THRESHOLD" | bc -l) )); then
                attack_found=true
            fi
        fi
        if [ "$shield_found" = false ]; then
            local sim=$(magick "$TEMP_SS" -crop ${WIDTH}x${HEIGHT}+${zone_x}+${ZONE_Y} png:- | python3 "$COMPARE_SCRIPT" "$SHIELD_BUFF" --stdin 2>/dev/null)
            if (( $(echo "${sim:-0} >= $THRESHOLD" | bc -l) )); then
                shield_found=true
            fi
        fi
        # Early exit if both found, or one found in quick mode
        if [ "$QUICK_BUFF" = true ]; then
            if [ "$attack_found" = true ] || [ "$shield_found" = true ]; then
                break
            fi
        else
            if [ "$attack_found" = true ] && [ "$shield_found" = true ]; then
                break
            fi
        fi
    done

    rm -f "$TEMP_SS"

    # Quick mode: at least one buff needed. Normal mode: both buffs needed.
    if [ "$QUICK_BUFF" = true ]; then
        if [[ "$attack_found" == true ]] || [[ "$shield_found" == true ]]; then
            return 0  # Valid buff
        else
            return 1  # Invalid buff
        fi
    else
        if [[ "$attack_found" == true ]] && [[ "$shield_found" == true ]]; then
            return 0  # Valid buff
        else
            return 1  # Invalid buff
        fi
    fi
}

validatePots() {
    # Minimum thresholds for potions
    local MIN_HEALTH_POTIONS=100
    local MIN_MANA_POTIONS=100

    # Read current potion counts from screen
    local CURRENT_HEALTH_POTIONS=$($PROJECT_DIR/bash/utils/readNumbers.sh 795 1047 57 20) # Migrated
    local CURRENT_MANA_POTIONS=$($PROJECT_DIR/bash/utils/readNumbers.sh 894 1047 57 20) # Migrated

    # Validate that we got numbers
    if [[ -z "$CURRENT_HEALTH_POTIONS" || ! "$CURRENT_HEALTH_POTIONS" =~ ^[0-9]+$ ]]; then
        echo "[$(date '+%H:%M:%S')] Warning: Could not read health potion count"
        CURRENT_HEALTH_POTIONS=0
    fi

    if [[ -z "$CURRENT_MANA_POTIONS" || ! "$CURRENT_MANA_POTIONS" =~ ^[0-9]+$ ]]; then
        echo "[$(date '+%H:%M:%S')] Warning: Could not read mana potion count"
        CURRENT_MANA_POTIONS=0
    fi

    echo "[$(date '+%H:%M:%S')] Current potions - Health: $CURRENT_HEALTH_POTIONS, Mana: $CURRENT_MANA_POTIONS"

    # Ignore health potion reading if it shows 0 (likely a read error)
    if [ $CURRENT_HEALTH_POTIONS -eq 0 ]; then
        echo "[$(date '+%H:%M:%S')] Health potions read as 0 - ignoring (likely OCR error)"
        # Only check mana potions in this case
        if [ $CURRENT_MANA_POTIONS -gt 0 ] && [ $CURRENT_MANA_POTIONS -lt $MIN_MANA_POTIONS ]; then
            echo "[$(date '+%H:%M:%S')] Low mana potions detected! (Min: Mana=$MIN_MANA_POTIONS)"
            return 1  # Return 1 to indicate low potions
        fi
        return 0  # Don't trigger buy if health is 0 (read error)
    fi

    # Normal validation when health reading is valid
    if [ $CURRENT_HEALTH_POTIONS -lt $MIN_HEALTH_POTIONS ] || [ $CURRENT_MANA_POTIONS -lt $MIN_MANA_POTIONS ]; then
        echo "[$(date '+%H:%M:%S')] Low potions detected! (Min: Health=$MIN_HEALTH_POTIONS, Mana=$MIN_MANA_POTIONS)"
        return 1  # Return 1 to indicate low potions
    fi

    return 0  # Potions are sufficient
}

runDuringTravelling() {
    # Parameters with default values
    local remainTime=${1:-10}  # Default 10 seconds if not specified
    local performRecycle=${2:-false}
    local validationType=${3:-"none"}  # Valid values: "angel", "satan", "none"
    local performGameValidation=${4:-false}  # Default false - only check game when explicitly requested
    local expectedLocation=${5:-0}  # Expected location constant (0 = no check)
    local popupValidation=${6:-false}  # Default false - check for expired popups

    local startTime
    local endTime
    local elapsed

    # Run recycling if requested
    if [ "$performRecycle" = true ]; then
        # echo "[$(date '+%H:%M:%S')] Running recycle during travel..."
        startTime=$(date +%s)
        performSingleRecycle
        endTime=$(date +%s)
        elapsed=$((endTime - startTime))
        remainTime=$((remainTime - elapsed))
        # echo "[$(date '+%H:%M:%S')] Recycle took ${elapsed}s, ${remainTime}s remaining"
    fi

    # Run validation based on type
    if [ "$validationType" = "angel" ]; then
        # echo "[$(date '+%H:%M:%S')] Validating Angel item during travel..."
        startTime=$(date +%s)
        validateAngelImp
        endTime=$(date +%s)
        elapsed=$((endTime - startTime))
        remainTime=$((remainTime - elapsed))
        # echo "[$(date '+%H:%M:%S')] Angel validation took ${elapsed}s, ${remainTime}s remaining"
    elif [ "$validationType" = "satan" ]; then
        # echo "[$(date '+%H:%M:%S')] Validating Satan item during travel..."
        startTime=$(date +%s)
        validateSatanImp
        endTime=$(date +%s)
        elapsed=$((endTime - startTime))
        remainTime=$((remainTime - elapsed))
        # echo "[$(date '+%H:%M:%S')] Satan validation took ${elapsed}s, ${remainTime}s remaining"
    fi

    # Check if game is running (only if requested)
    local gameValidationFailed=false
    if [ "$performGameValidation" = true ]; then
        # echo "[$(date '+%H:%M:%S')] Checking if game is running..."
        startTime=$(date +%s)
        if ! isGameRunning; then
            echo "[$(date '+%H:%M:%S')] Game validation failed: Game is closed!"
            gameValidationFailed=true
            $PROJECT_DIR/bash/actions/openGame.sh
            sleep 2
        elif ! isLoggedIn; then
            echo "[$(date '+%H:%M:%S')] Game validation failed: Not logged in!"
            gameValidationFailed=true
            $PROJECT_DIR/bash/actions/login.sh
            sleep 2
        elif ! isCharacterSelected; then
            echo "[$(date '+%H:%M:%S')] Game validation failed: Character not selected!"
            gameValidationFailed=true
            ((gameClosedCount++))
            $PROJECT_DIR/bash/actions/selectCharacter.sh
            sleep 2
        fi
        endTime=$(date +%s)
        elapsed=$((endTime - startTime))
        remainTime=$((remainTime - elapsed))
    fi

    # Check for expired popups (only if requested)
    if [ "$popupValidation" = true ]; then
        startTime=$(date +%s)
        detectAndCloseExpiredPopup
        endTime=$(date +%s)
        elapsed=$((endTime - startTime))
        remainTime=$((remainTime - elapsed))
    fi

    # Check location validation (only if expected location is specified)
    local locationValidationFailed=false
    if [ "$expectedLocation" -ne 0 ]; then
        startTime=$(date +%s)
        local currentLocation=$(getLocation)
        if [ "$currentLocation" -ne "$expectedLocation" ]; then
            local expectedName=$(getLocationName $expectedLocation)
            local currentName=$(getLocationName $currentLocation)
            echo "[$(date '+%H:%M:%S')] Location validation failed: Expected $expectedName, got $currentName"
            locationValidationFailed=true
        fi
        endTime=$(date +%s)
        elapsed=$((endTime - startTime))
        remainTime=$((remainTime - elapsed))
    fi

    # Sleep for remaining time
    if [ $remainTime -gt 0 ]; then
        # echo "[$(date '+%H:%M:%S')] Waiting ${remainTime}s for travel to complete..."
        sleep $remainTime
    fi

    # Return failure codes based on validation results
    # Exit code 1 = game validation failed
    # Exit code 2 = location validation failed
    if [ "$gameValidationFailed" = true ]; then
        return 1
    fi
    if [ "$locationValidationFailed" = true ]; then
        return 2
    fi
    return 0
}

# Wait for a process while monitoring for pause keys (p, s, n, b, q, r)
# Parameters: $1 = PID to monitor
# Exit codes:
#   0  = Process completed normally
#   1  = Continue/skip to next loop ("n" key)
#   2  = Force buff ("b" key)
#   3  = Force Devil Square event ("q" key)
#   4  = Force Blood Castle event ("r" key)
#   10 = Abort execution (other keys or from wait.sh)
waitProcessWithKeyMonitoring() {
    local pid=$1

    while kill -0 $pid 2>/dev/null; do
        read -t 1 -n 1 key
        if [ $? = 0 ]; then
            kill $pid 2>/dev/null
            wait $pid 2>/dev/null

            if [ "$key" = "p" ]; then
                $PROJECT_DIR/bash/actions/wait.sh
                local wait_exit_code=$?
                return $wait_exit_code
            elif [ "$key" = "s" ]; then
                $PROJECT_DIR/bash/actions/wait.sh 0
                local wait_exit_code=$?
                return $wait_exit_code
            elif [ "$key" = "n" ]; then
                echo " key pressed. Skipping..."
                return 1
            elif [ "$key" = "b" ]; then
                echo " key pressed. Forcing buff..."
                return 2
            elif [ "$key" = "q" ]; then
                echo " key pressed. Forcing Devil Square event..."
                return 3
            elif [ "$key" = "r" ]; then
                echo " key pressed. Forcing Blood Castle event..."
                return 4
            else
                echo " key pressed. Aborting..."
                return 10
            fi
        fi
    done

    wait $pid
    return 0 # Natural ending
}

# Helper function to get location name from constant
# Parameters: $1 = Location constant
# Returns: Human-readable location name
getLocationName() {
    local location=$1
    case $location in
        $LOC_PLAIN_OF_WINDS_1) echo "Plain of Winds 1" ;;
        $LOC_PLAIN_OF_WINDS_2) echo "Plain of Winds 2" ;;
        $LOC_KANTURU_RELICS_2) echo "Kanturu Relics 2" ;;
        $LOC_LORENCIA) echo "Lorencia" ;;
        $LOC_SWAMP_OF_PEACE) echo "Swamp of Peace" ;;
        $LOC_RAKLION_3) echo "Raklion 3" ;;
        $LOC_RAKLION_2) echo "Raklion 2" ;;
        $LOC_DIVINE_REALM) echo "Divine Realm" ;;
        $LOC_HIGH_HEAVEN) echo "High Heaven" ;;
        $LOC_PURGATORY_OF_MISERY) echo "Purgatory of Misery" ;;
        $LOC_ENDLESS_ABYSS) echo "Endless Abyss" ;;
        $LOC_CORRIDOR_OF_AGONY) echo "Corridor of Agony" ;;
        $LOC_SANCTUARY_1) echo "Sanctuary 1" ;;
        $LOC_CORRUPTED_LANDS) echo "Corrupted Lands" ;;
        $LOC_LAND_OF_DEMONS) echo "Lands of Demons" ;;
        $LOC_SANCTUARY_2) echo "Sanctuary 2" ;;
        $LOC_SANCTUARY_3) echo "Sanctuary 3" ;;
        $LOC_SANCTUARY_4) echo "Sanctuary 4" ;;
        $LOC_SANCTUARY_5) echo "Sanctuary 5" ;;
        $LOC_SANCTUARY_6) echo "Sanctuary 6" ;;
        $LOC_FOGGY_FOREST) echo "Foggy Forest" ;;
        $LOC_EVERSONG_FOREST) echo "Eversong Forest" ;;
        $LOC_DEVIL_SQUARE) echo "Devil Square" ;;
        $LOC_BLOOD_CASTLE) echo "Blood Castle" ;;
        $LOC_ABYSSAL_FEREA) echo "Abyssal Ferea" ;;
        *) echo "Unknown ($location)" ;;
    esac
}

# Function to teleport to a specific location with validation
# Parameters: $1 = Location constant (LOC_PLAIN_OF_WINDS_1, LOC_RAKLION_3, etc.)
# Exit codes:
#   0  = Successfully arrived at location
#   1  = User skipped to next loop
#   2  = User wants to force buff
#   3  = User wants to force Devil Square event
#   4  = User wants to force Blood Castle event
#   5  = Failed after max retries (game is running but teleport failed)
#   6  = Game was not running, recovery attempted
#   10 = User aborted
# Retries up to 3 times if location validation fails
teleportTo() {
    local targetLocation=$1
    local maxRetries=3
    local attempt=0
    local teleportScript=""
    local locationName=$(getLocationName $targetLocation)

    # Map location constant to teleport script
    case $targetLocation in
        $LOC_PLAIN_OF_WINDS_1)
            teleportScript="$PROJECT_DIR/bash/teleport/toPlainOfFourWinds1.sh"
            ;;
        $LOC_KANTURU_RELICS_2)
            teleportScript="$PROJECT_DIR/bash/teleport/toKanturuRelics2.sh"
            ;;
        $LOC_LORENCIA)
            teleportScript="$PROJECT_DIR/bash/teleport/toLorencia.sh"
            ;;
        $LOC_SWAMP_OF_PEACE)
            teleportScript="$PROJECT_DIR/bash/teleport/toSwampOfPeace.sh"
            ;;
        $LOC_RAKLION_3)
            teleportScript="$PROJECT_DIR/bash/teleport/toRaklion3.sh"
            ;;
        $LOC_RAKLION_2)
            teleportScript="$PROJECT_DIR/bash/teleport/toRaklion2.sh"
            ;;
        $LOC_DIVINE_REALM)
            teleportScript="$PROJECT_DIR/bash/teleport/toDivine.sh"
            ;;
        $LOC_HIGH_HEAVEN)
            teleportScript="$PROJECT_DIR/bash/teleport/toHighHeaven.sh"
            ;;
        $LOC_PURGATORY_OF_MISERY)
            teleportScript="$PROJECT_DIR/bash/teleport/toPurgatoryOfMissery.sh"
            ;;
        $LOC_ENDLESS_ABYSS)
            teleportScript="$PROJECT_DIR/bash/teleport/toEndlessAbyss.sh"
            ;;
        $LOC_CORRIDOR_OF_AGONY)
            teleportScript="$PROJECT_DIR/bash/teleport/toCorridorOfAgony.sh"
            ;;
        $LOC_SANCTUARY_1)
            teleportScript="$PROJECT_DIR/bash/teleport/toSanctuary.sh 1"
            ;;
        $LOC_CORRUPTED_LANDS)
            teleportScript="$PROJECT_DIR/bash/teleport/toCorruptedLands.sh"
            ;;
        $LOC_LAND_OF_DEMONS)
            teleportScript="$PROJECT_DIR/bash/teleport/toLandOfDemons.sh"
            ;;
        $LOC_SANCTUARY_2)
            teleportScript="$PROJECT_DIR/bash/teleport/toSanctuary.sh 2"
            ;;
        $LOC_SANCTUARY_3)
            teleportScript="$PROJECT_DIR/bash/teleport/toSanctuary.sh 3"
            ;;
        $LOC_SANCTUARY_4)
            teleportScript="$PROJECT_DIR/bash/teleport/toSanctuary.sh 4"
            ;;
        $LOC_SANCTUARY_5)
            teleportScript="$PROJECT_DIR/bash/teleport/toSanctuary.sh 5"
            ;;
        $LOC_SANCTUARY_6)
            teleportScript="$PROJECT_DIR/bash/teleport/toSanctuary.sh 6"
            ;;
        $LOC_FOGGY_FOREST)
            teleportScript="$PROJECT_DIR/bash/teleport/toFoggyForest.sh"
            ;;
        $LOC_EVERSONG_FOREST)
            teleportScript="$PROJECT_DIR/bash/teleport/toEversongForest.sh"
            ;;
        $LOC_ABYSSAL_FEREA)
            teleportScript="$PROJECT_DIR/bash/teleport/toAbyssalFerea.sh"
            ;;
        *)
            echo "[$(date '+%H:%M:%S')] Error: Unknown location: $locationName" >&2
            return 1
            ;;
    esac

    # Retry loop
    while [ $attempt -lt $maxRetries ]; do
        ((attempt++))
        echo "[$(date '+%H:%M:%S')] Teleporting to $locationName (Attempt $attempt/$maxRetries)..."

        # Execute teleport script with key monitoring
        $teleportScript &
        local teleportPID=$!
        waitProcessWithKeyMonitoring $teleportPID
        local monitorResult=$?

        # Handle user key pressed during teleport
        if [[ $monitorResult -eq 1 ]]; then
            # User wants to skip to next loop
            echo "[$(date '+%H:%M:%S')] Teleport skipped by user"
            return 1
        elif [[ $monitorResult -eq 2 ]]; then
            # User wants to force buff
            echo "[$(date '+%H:%M:%S')] Teleport skipped, force buff requested"
            return 2
        elif [[ $monitorResult -eq 3 ]]; then
            # User wants to force Devil Square event
            echo "[$(date '+%H:%M:%S')] Teleport skipped, force Devil Square event requested"
            return 3
        elif [[ $monitorResult -eq 4 ]]; then
            # User wants to force Blood Castle event
            echo "[$(date '+%H:%M:%S')] Teleport skipped, force Blood Castle event requested"
            return 4
        elif [[ $monitorResult -eq 10 ]]; then
            # User wants to abort
            echo "[$(date '+%H:%M:%S')] Teleport aborted by user" >&2
            return 10
        fi

        # Small delay to let the screen update
        sleep 4

        # Validate we arrived at the correct location
        local currentLocation=$(getLocation)

        if [ "$currentLocation" -eq "$targetLocation" ]; then
            echo "[$(date '+%H:%M:%S')] Successfully arrived at $locationName"
            return 0
        else
            local currentLocationName=$(getLocationName $currentLocation)
            echo "[$(date '+%H:%M:%S')] Location mismatch: expected $locationName, got $currentLocationName" >&2

            if [ $attempt -lt $maxRetries ]; then
                echo "[$(date '+%H:%M:%S')] Retrying teleport..." >&2
                sleep 3
            fi
        fi
    done

    echo "[$(date '+%H:%M:%S')] Failed to teleport to $locationName after $maxRetries attempts" >&2

    # Game check - teleport failures might indicate game is closed/frozen
    echo "[$(date '+%H:%M:%S')] Checking game state after teleport failure..."
    if ! isGameRunning; then
        echo "[$(date '+%H:%M:%S')] Game is not running! Attempting recovery..."
        $PROJECT_DIR/bash/actions/openGame.sh
        sleep 5
        $PROJECT_DIR/bash/actions/login.sh
        sleep 2
        $PROJECT_DIR/bash/actions/selectCharacter.sh
        sleep 2
        return 6  # Return 6 to indicate game was recovered
    fi

    return 5
}

leaveParty() {
    # Reference image path
    REFERENCE_IMAGE="$PROJECT_DIR/img/empty_team.png"

    # Party slot coordinates
    X=505 # Migrated
    Y=328 # Migrated
    WIDTH=250 # Migrated
    HEIGHT=500 # Migrated

    # echo "[$(date '+%H:%M:%S')] Checking Angel item in inventory..."

    # Quest tap to avoid issues
    tap_left_quest_tab
    sleep 0.5
    # Team Up tab
    tap_left_team_tab
    sleep 0.5
    # Team Up tab to open team pop-up
    tap_left_team_tab
    sleep 1

    # Check if empty slot is visible
    result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$REFERENCE_IMAGE")

    if [[ "$result" == "similar" ]]; then
        # echo "[$(date '+%H:%M:%S')] No party"
        # Close
        tap_party_pop_up_close
        sleep 1
        # Quest tap to avoid issues
        tap_left_quest_tab
        return 0
    else
        # echo "[$(date '+%H:%M:%S')] At party. Leaving..."
        sleep 1
        tap_party_pop_up_leave
        sleep 0.5
        # Close
        tap_party_pop_up_close
        sleep 1
        # Quest tap to avoid issues
        tap_left_quest_tab
        return 1
    fi
}

forceAutoParty() {
    # Reference image path
    local REFERENCE_IMAGE="$PROJECT_DIR/img/check_auto_party.png"

    # Auto party checkbox coordinates
    local X=121 # Migrated
    local Y=315 # Migrated
    local WIDTH=45 # Migrated
    local HEIGHT=45 # Migrated
    
    # Quest tap to avoid issues
    tap_left_quest_tab
    sleep 0.5
    # Team Up tab
    tap_left_team_tab
    sleep 0.5

    # Check if auto party checkbox is checked
    local result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$REFERENCE_IMAGE")

    if [[ "$result" == "similar" ]]; then
        # Auto party is already ON
        # Quest tap to avoid issues
        tap_left_quest_tab
        return 1
    else
        # Auto party is OFF, enable it
        tap_auto_party_box
        sleep 0.5
        # Quest tap to avoid issues
        tap_left_quest_tab
        return 0
    fi
}

autoSkill() {
    # AUTO SKILL - Repeatedly press a skill key with cooldown
    # Press 'p' to pause, 'c' to cancel and exit
    #
    # Parameters:
    #   $1 - Duration in seconds (optional, infinite if not provided)
    #   $2 - Key code to press (default 5)
    #   $3 - Cooldown in seconds (default 3)
    # ==================================================

    local duration=${1:-0}      # 0 = infinite
    local keyCode=${2:-5}       # Default key code 5
    local cooldown=${3:-3}      # Default 3 second cooldown

    local skillCount=0
    local isPaused=false
    local pauseFlagFile="/tmp/mubot_skill_paused"
    local startTime=$(date +%s)

    while true; do
        # Check duration limit (if not infinite)
        if [ $duration -gt 0 ]; then
            local currentTime=$(date +%s)
            local elapsed=$((currentTime - startTime))
            if [ $elapsed -ge $duration ]; then
                # echo "[$(date '+%H:%M:%S')] Duration reached. Total skills pressed: $skillCount"
                rm -f "$pauseFlagFile"
                return 0
            fi
        fi

        # Press the skill
        if [ "$isPaused" = false ]; then
            tap_skill_5
            ((skillCount++))
            # echo "[$(date '+%H:%M:%S')] Key $keyCode pressed ($skillCount times)"
        fi

        # Wait for cooldown while checking for user input
        local elapsed=0
        while [ $elapsed -lt $cooldown ]; do
            read -t 1 -n 1 key
            if [ $? = 0 ]; then
                if [[ $key == "p" ]]; then
                    if [ "$isPaused" = false ]; then
                        echo "[$(date '+%H:%M:%S')] Paused. Press 'p' again to resume..."
                        isPaused=true
                        touch "$pauseFlagFile"
                    else
                        echo "[$(date '+%H:%M:%S')] Resumed."
                        isPaused=false
                        rm -f "$pauseFlagFile"
                    fi
                elif [[ $key == "c" ]]; then
                    echo "[$(date '+%H:%M:%S')] Cancelled. Total skills pressed: $skillCount"
                    rm -f "$pauseFlagFile"
                    return 0
                fi
            fi

            if [ "$isPaused" = false ]; then
                ((elapsed++))
            fi
        done
    done
}
