#!/bin/bash
# EVENT UTILITIES
# Functions for checking event times and handling event-related operations
# ==================================================

# Load configuration
source $PROJECT_DIR/config/variables.sh

# Open the Daily Goals window from the top buttons menu
openDailyGoals() {
    # Auto attack to make sure top buttons are hidden
    tap_auto
    sleep 1
    tap_auto
    sleep 0.5

    # Click expand top buttons
    tap_more_top_button
    sleep 0.5
    # Click Daily Goal
    tap_more_top_daily_goal
}

# Open Daily Goals and collect all chests (A through E)
openDailyGoalsChests() {
    openDailyGoals
    sleep 0.5

    # Chest A
    tap_daily_goal_chest_a
    sleep 0.5
    tap_daily_goal_chest_claim
    sleep 0.5
    tap_daily_goal_chest_close
    sleep 0.5

    # Chest B
    tap_daily_goal_chest_b
    sleep 0.5
    tap_daily_goal_chest_claim
    sleep 0.5
    tap_daily_goal_chest_close
    sleep 0.5

    # Chest C
    tap_daily_goal_chest_c
    sleep 0.5
    tap_daily_goal_chest_claim
    sleep 0.5
    tap_daily_goal_chest_close
    sleep 0.5

    # Chest D
    tap_daily_goal_chest_d
    sleep 0.5
    tap_daily_goal_chest_claim
    sleep 0.5
    tap_daily_goal_chest_close
    sleep 0.5

    # Chest E
    tap_daily_goal_chest_e
    sleep 0.5
    tap_daily_goal_chest_claim
    sleep 0.5
    tap_daily_goal_chest_close
    sleep 0.5

    tap_daily_goal_close
}

# Change auto-play plan
# Parameters: $1 = plan number (1 = Evil Spirit, 2 = Blizzard)
changePlan() {
    local plan=${1:-1}
    
    sleep 1
    # Click on more button
    tap_more_right_button
    sleep 0.5
    # Click on settings button
    tap_more_right_settings
    sleep 0.5
    # Click on Auto-Play button from settings
    tap_settings_auto_tab
    sleep 0.5
    # Select plan
    if [ "$plan" -eq 1 ]; then
        # Plan 1 - Evil Spirit
        tap_settings_auto_plan1
        echo "[$(date '+%H:%M:%S')] Changed to Evil Spirit Plan."
    else
        # Plan 2 - Blizzard
        tap_settings_auto_plan2
        echo "[$(date '+%H:%M:%S')] Changed to Blizzard Plan."
    fi
    sleep 0.5
    # Close windows to go back to game
    tap_close_by_outside
    sleep 0.5
    
    # Click on more button to avoid issues
    tap_more_right_button
    sleep 1
}

# Wait for event countdown and click Go button when ready
# Reads remain time from screen. If not available, waits 105s as fallback.
# Then clicks Go button repeatedly until it disappears (event started) with 30s timeout.
# Returns: epoch time when event started (via echo)
waitToStartEvent() {
    remainTime=$(checkRemainTimeForEventToStart)
    if [ $? -eq 0 ] && [ "$remainTime" -gt 0 ]; then
        echo "[$(date '+%H:%M:%S')] Waiting ${remainTime}s for event to start..." >&2
        sleep $remainTime
    else
        echo "[$(date '+%H:%M:%S')] Could not read timer. Waiting 105s..." >&2
        sleep 105
    fi

    # Click Go button and wait until event starts (button disappears)
    local startTimeout=30
    local startElapsed=0
    while [ $startElapsed -lt $startTimeout ]; do
        if isOpenNowButtonVisible; then
            echo "[$(date '+%H:%M:%S')] Open now button visible. Clicking..." >&2
            tap_event_open_now
            sleep 3
            startElapsed=$((startElapsed + 3))
        else
            echo "[$(date '+%H:%M:%S')] Event has started." >&2
            break
        fi
    done
    if [ $startElapsed -ge $startTimeout ]; then
        echo "[$(date '+%H:%M:%S')] Timeout waiting for event to start. Continuing..." >&2
    fi

    # Return epoch time
    date +%s
}

# Wait for "Event is over" screen after event ends
# Checks every 5 seconds with 30s timeout, then taps to close the window
waitToEndEvent() {
    local eventOverTimeout=30
    local eventOverElapsed=0
    while [ $eventOverElapsed -lt $eventOverTimeout ]; do
        if isEventOver; then
            echo "[$(date '+%H:%M:%S')] Event is over screen detected."
            sleep 1
            # Tap close "X" button
            tap_event_scoreboard_close
            break
        fi
        sleep 5
        eventOverElapsed=$((eventOverElapsed + 5))
    done
    if [ $eventOverElapsed -ge $eventOverTimeout ]; then
        echo "[$(date '+%H:%M:%S')] Timeout waiting for event over screen. Closing anyway..."
        # Tap close "X" button
        tap_event_scoreboard_close
    fi

    echo "[$(date '+%H:%M:%S')] Exit event..."
    sleep 2
}

# Function to check if current time is within a specific time range (same hour)
# Parameters: $1 = start minute, $2 = end minute
# Returns: 0 if within range, 1 if outside range
# Example: isTimeInRange 0 5  # checks if time is between XX:00 and XX:05
isTimeInRange() {
    local startMinute=$1
    local endMinute=$2
    local currentMinute=$(date '+%M' | sed 's/^0*//')  # Remove leading zeros

    # Handle empty string (when minute is 00)
    if [ -z "$currentMinute" ]; then
        currentMinute=0
    fi

    if [ $currentMinute -ge $startMinute ] && [ $currentMinute -le $endMinute ]; then
        return 0  # Within range
    else
        return 1  # Outside range
    fi
}

# Function to check if it's time for Devil Square event
# Hours and minutes configured in local.properties
# Returns: 0 if it's Devil Square time, 1 otherwise
isDevilSquareTime() {
    local currentHour=$(date '+%H' | sed 's/^0*//')  # Get hour, remove leading zeros

    # Handle empty string (when hour is 00)
    if [ -z "$currentHour" ]; then
        currentHour=0
    fi

    # Check if current hour matches any configured hour
    IFS=',' read -ra dsHours <<< "$EVENT_DS_HOURS"
    for h in "${dsHours[@]}"; do
        if [ "$currentHour" -eq "$h" ]; then
            isTimeInRange $EVENT_DS_MINUTES_START $EVENT_DS_MINUTES_END
            return $?
        fi
    done
    return 1
}

# Function to check if it's time for Blood Castle event
# Hours and minutes configured in local.properties
# Returns: 0 if it's Blood Castle time, 1 otherwise
isBloodCastleTime() {
    local currentHour=$(date '+%H' | sed 's/^0*//')  # Get hour, remove leading zeros

    # Handle empty string (when hour is 00)
    if [ -z "$currentHour" ]; then
        currentHour=0
    fi

    # Check if current hour matches any configured hour
    IFS=',' read -ra bcHours <<< "$EVENT_BC_HOURS"
    for h in "${bcHours[@]}"; do
        if [ "$currentHour" -eq "$h" ]; then
            isTimeInRange $EVENT_BC_MINUTES_START $EVENT_BC_MINUTES_END
            return $?
        fi
    done
    return 1
}

# Function to handle periodic recycling and use skill during events
# Parameters: $1 = total duration in seconds, $2 = recycle interval in seconds
# Used in event scripts like Blood Castle, Devil Square, etc.
# Function to find and click GO button for a specific event
# Reads headers of visible event panels and clicks the GO button when found
# Scrolls horizontally if the event is not visible in current view
# Parameters: $1 = search text (case-insensitive partial match, e.g. "blood" for Blood Castle)
# Returns: 0 if event found and clicked, 1 if not found after scrolling
# Header positions (x): 666, 1110, 1554, 1998 (y: 330, width: 400, height: 40)
# GO button positions (x): 845, 1290, 1731, 2175 (y: 1075)
clickEventGoButton() {
    local searchText="$1"
    local searchLower=$(echo "$searchText" | tr '[:upper:]' '[:lower:]')

    # Header X positions and corresponding GO button X positions
    local headerXPositions=(315 670 1015 1375) # Migrated
    local buttonXPositions=(438 790 1150 1500) # Migrated
    local headerY=266 # Migrated
    local headerWidth=290 # Migrated
    local headerHeight=30 # Migrated
    local buttonY=860 # Migrated

    local OCR_SCRIPT="$PROJECT_DIR/python/readTextOCR.py"

    # Check each of the 4 visible panels
    for i in 0 1 2 3; do
        local hx=${headerXPositions[$i]}
        local bx=${buttonXPositions[$i]}

        # Read header text via OCR
        local headerText
        headerText=$(adb_screencap | \
            magick png:- -crop ${headerWidth}x${headerHeight}+${hx}+${headerY} \
            -colorspace Gray \
            -contrast-stretch 0 \
            -threshold 60% \
            -scale 300% \
            png:- | \
            python3 "$OCR_SCRIPT" --stdin 2>/dev/null)

        local headerLower=$(echo "$headerText" | tr '[:upper:]' '[:lower:]')

        if [[ "$headerLower" == *"$searchLower"* ]]; then
            echo "[$(date '+%H:%M:%S')] Found '$searchText' at panel $((i+1)): '$headerText'"
            adb_tap $bx $buttonY
            return 0
        fi
    done

    echo "[$(date '+%H:%M:%S')] ERROR: Event '$searchText' not found"
    return 1
}

# Run during event: taps skill every 3 seconds, recycles every 3 minutes
# Reads remain time from screen once. If not available, calculates 10 minutes from start time.
# Parameters: $1 = epoch time when start button was pressed
runWhileEvent() {
    local startEpoch=$1
    local tapInterval=3
    local eventDuration=600  # 10 minutes default

    # Calculate remaining time from start time
    local now=$(date +%s)
    local elapsedSinceStart=$((now - startEpoch))
    eventDuration=$((600 - elapsedSinceStart))
    echo "[$(date '+%H:%M:%S')] Running event for ${eventDuration}s..."

    local elapsed=0
    local recycleInterval=180  # Recycle every 3 minutes
    local sinceLastRecycle=0
    while [ $elapsed -lt $eventDuration ]; do
        tap_skill_5
        sleep $tapInterval
        elapsed=$((elapsed + tapInterval))
        sinceLastRecycle=$((sinceLastRecycle + tapInterval))

        # Recycle every 3 minutes
        if [ $sinceLastRecycle -ge $recycleInterval ]; then
            echo "[$(date '+%H:%M:%S')] Recycling inventory... (${elapsed}s/${eventDuration}s)"
            $PROJECT_DIR/bash/actions/recycle.sh
            sleep 1
            tap_close_by_outside
            sinceLastRecycle=0
        fi
    done
    echo "[$(date '+%H:%M:%S')] Event time ended"
}
