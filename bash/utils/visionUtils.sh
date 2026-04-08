#!/bin/bash

# Guard against multiple sourcing
if [ -n "$_VISION_UTILS_LOADED" ]; then
    return 0 2>/dev/null || true
fi
_VISION_UTILS_LOADED=1

# Load configuration for device targeting
source $PROJECT_DIR/config/variables.sh

# ============================================
# Location Constants (Enum-like values)
# ============================================
readonly LOC_UNKNOWN=0
readonly LOC_PLAIN_OF_WINDS_1=1
readonly LOC_PLAIN_OF_WINDS_2=2
readonly LOC_KANTURU_RELICS_2=3
readonly LOC_LORENCIA=4
readonly LOC_SWAMP_OF_PEACE=5
readonly LOC_RAKLION_3=6
readonly LOC_RAKLION_2=7
readonly LOC_DIVINE_REALM=8
readonly LOC_HIGH_HEAVEN=9
readonly LOC_PURGATORY_OF_MISERY=10
readonly LOC_ENDLESS_ABYSS=11
readonly LOC_CORRIDOR_OF_AGONY=12
readonly LOC_CORRUPTED_LANDS=14
readonly LOC_LAND_OF_DEMONS=15
readonly LOC_FOGGY_FOREST=17
readonly LOC_EVERSONG_FOREST=18
readonly LOC_DEVIL_SQUARE=19
readonly LOC_BLOOD_CASTLE=20
readonly LOC_ABYSSAL_FEREA=25
readonly LOC_SANCTUARY=99

# ============================================
# Daily Goal Event Constants
# ============================================
readonly DG_MYSTICLAND_BOSS=1
readonly DG_BLOOD_CASTLE=2
readonly DG_COURAGE_TRIAL=3
readonly DG_KUNDUN_TRIAL=4
readonly DG_GOLDEN_MONSTER=5
readonly DG_FIELD_BOSS=6
readonly DG_DEVIL_SQUARE=7
readonly DG_WARRIOR_QUEST=8

# Script to check if a cropped zone has red tone dominance
# Returns: "true" if red tones are dominant, "false" otherwise
# Function to read numbers from a cropped screen region
# Parameters: X Y WIDTH HEIGHT [THRESHOLD]
# Returns: Detected numbers as a string
# Exit code: 0 on success, 1 on failure
readNumbersFromZone() {
    local X=$1
    local Y=$2
    local WIDTH=$3
    local HEIGHT=$4
    local THRESHOLD=${5:-60}  # Default threshold is 60%

    # Local debug flag - set to true to save cropped images to Desktop
    local DEBUG_SAVE_IMAGE=false

    # Validate parameters
    if [[ -z "$X" || -z "$Y" || -z "$WIDTH" || -z "$HEIGHT" ]]; then
        echo "Error: Missing parameters. Usage: readNumbersFromZone X Y WIDTH HEIGHT [THRESHOLD]" >&2
        return 1
    fi

    # Setup temp file path only if debugging
    local TEMP_FILE=""
    if [ "$DEBUG_SAVE_IMAGE" = true ]; then
        local DESKTOP_DIR="$HOME/Desktop"
        TEMP_FILE="${DESKTOP_DIR}/temp_ocr_crop_${X}_${Y}.png"
    fi

    # Get OCR script path
    local OCR_SCRIPT="$PROJECT_DIR/python/readNumbersOCR.py"

    # Capture screenshot, crop, and enhance for OCR
    # Using ImageMagick preprocessing to improve OCR accuracy:
    # - Convert to grayscale
    # - Scale up for better recognition
    local DETECTED_TEXT

    if [ "$DEBUG_SAVE_IMAGE" = true ]; then
        # DEBUG MODE: Save to disk AND pipe to Python
        DETECTED_TEXT=$(adb_screencap | \
            magick png:- -crop ${WIDTH}x${HEIGHT}+${X}+${Y} \
            -colorspace Gray \
            -scale 300% \
            png:- | \
            tee "$TEMP_FILE" | \
            python3 "$OCR_SCRIPT" --stdin 2>/dev/null)

        echo "[DEBUG] Saved cropped image to: $TEMP_FILE" >&2
    else
        # NORMAL MODE: Everything in memory (no SSD writes)
        DETECTED_TEXT=$(adb_screencap | \
            magick png:- -crop ${WIDTH}x${HEIGHT}+${X}+${Y} \
            -colorspace Gray \
            -scale 300% \
            png:- | \
            python3 "$OCR_SCRIPT" --stdin 2>/dev/null)
    fi

    # Return the detected numbers
    if [[ -n "$DETECTED_TEXT" ]]; then
        echo "$DETECTED_TEXT"
        return 0
    else
        echo ""
        return 1
    fi
}

# Function to read text from a specific screen zone using OCR
# Parameters: X Y WIDTH HEIGHT [THRESHOLD]
# Returns: Detected text or empty string if no text found
# Exit code: 0 if text detected, 1 if not
readTextFromZone() {
    local X=$1
    local Y=$2
    local WIDTH=$3
    local HEIGHT=$4
    local THRESHOLD=${5:-60}  # Default threshold is 60%

    # Local debug flag - set to true to save cropped images to Desktop
    local DEBUG_SAVE_IMAGE=false

    # Validate parameters
    if [[ -z "$X" || -z "$Y" || -z "$WIDTH" || -z "$HEIGHT" ]]; then
        echo "Error: Missing parameters. Usage: readTextFromZone X Y WIDTH HEIGHT [THRESHOLD]" >&2
        return 1
    fi

    # Setup temp file path only if debugging
    local TEMP_FILE=""
    if [ "$DEBUG_SAVE_IMAGE" = true ]; then
        local DESKTOP_DIR="$HOME/Desktop"
        TEMP_FILE="${DESKTOP_DIR}/temp_text_ocr_crop_${X}_${Y}.png"
    fi

    # Get OCR script path
    local OCR_SCRIPT="$PROJECT_DIR/python/readTextOCR.py"

    # Capture screenshot, crop, and enhance for OCR
    # Using ImageMagick preprocessing to improve OCR accuracy:
    # - Convert to grayscale
    # - Increase contrast
    # - Apply threshold for better text recognition
    local DETECTED_TEXT

    if [ "$DEBUG_SAVE_IMAGE" = true ]; then
        # DEBUG MODE: Save to disk AND pipe to Python
        DETECTED_TEXT=$(adb_screencap | \
            magick png:- -crop ${WIDTH}x${HEIGHT}+${X}+${Y} \
            -colorspace Gray \
            -contrast-stretch 0 \
            -threshold ${THRESHOLD}% \
            -scale 300% \
            png:- | \
            tee "$TEMP_FILE" | \
            python3 "$OCR_SCRIPT" --stdin 2>/dev/null)

        echo "[DEBUG] Saved cropped image to: $TEMP_FILE" >&2
    else
        # NORMAL MODE: Everything in memory (no SSD writes)
        DETECTED_TEXT=$(adb_screencap | \
            magick png:- -crop ${WIDTH}x${HEIGHT}+${X}+${Y} \
            -colorspace Gray \
            -contrast-stretch 0 \
            -threshold ${THRESHOLD}% \
            -scale 300% \
            png:- | \
            python3 "$OCR_SCRIPT" --stdin 2>/dev/null)
    fi

    # Return the detected text
    if [[ -n "$DETECTED_TEXT" ]]; then
        echo "$DETECTED_TEXT"
        return 0
    else
        echo ""
        return 1
    fi
}

# Function to check remaining time for event to end
# Reads red text at position 718,450 in mm:ss format

# Function to check remaining time for event to start
# Reads red text at position (TBD) in mm:ss format
# Returns: remaining time in seconds, or -1 if unable to read
# Exit code: 0 if time read successfully, 1 if failed
checkRemainTimeForEventToStart() {
    local X=140
    local Y=263
    local WIDTH=69
    local HEIGHT=23

    # Get OCR script path
    local OCR_SCRIPT="$PROJECT_DIR/python/readTextOCR.py"

    # Capture screenshot, crop, isolate red channel, and OCR
    local DETECTED_TEXT
    DETECTED_TEXT=$(adb_screencap | \
        magick png:- -crop ${WIDTH}x${HEIGHT}+${X}+${Y} \
        -channel R -separate \
        -negate \
        -contrast-stretch 0 \
        -threshold 60% \
        -scale 300% \
        png:- | \
        python3 "$OCR_SCRIPT" --stdin 2>/dev/null)

    # Try to extract mm:ss or mm.ss pattern (OCR may read colon as dot)
    local timeMatch
    timeMatch=$(echo "$DETECTED_TEXT" | grep -oE '[0-9]{1,2}[:.][0-9]{2}')

    if [[ -n "$timeMatch" ]]; then
        local minutes=$(echo "$timeMatch" | sed 's/[:.]/\n/' | head -1)
        local seconds=$(echo "$timeMatch" | sed 's/[:.]/\n/' | tail -1)
        minutes=$((10#$minutes))
        seconds=$((10#$seconds))
        local totalSeconds=$(( minutes * 60 + seconds ))
        echo "$totalSeconds"
        return 0
    else
        echo "-1"
        return 1
    fi
}

# Function to get current map location by reading location text from screen
# Returns: Location constant (LOC_PLAIN_OF_WINDS_1, LOC_RAKLION_3, etc.)
# Exit code: Always 0
getLocation() {
    # Open map to show location text
    tap_openMap
    sleep 1

    # Read location text from the map name zone
    local locationText=$(readTextFromZone 610 145 280 28) # Migrated

    # Close map
    tap_closeMap
    sleep 0.2

    # Convert to lowercase for case-insensitive comparison
    local locationLower=$(echo "$locationText" | tr '[:upper:]' '[:lower:]')

    # Check which map we're on (using partial match for flexibility)
    if [[ "$locationLower" == *"plain"* && "$locationLower" == *"1"* ]]; then
        echo $LOC_PLAIN_OF_WINDS_1
    elif [[ "$locationLower" == *"plain"* && "$locationLower" == *"2"* ]]; then
        echo $LOC_PLAIN_OF_WINDS_2
    elif [[ "$locationLower" == *"relic"* && "$locationLower" == *"2"* ]]; then
        echo $LOC_KANTURU_RELICS_2
    elif [[ "$locationLower" == *"lorencia"* ]]; then
        echo $LOC_LORENCIA
    elif [[ "$locationLower" == *"swamp"* && "$locationLower" == *"peace"* ]]; then
        echo $LOC_SWAMP_OF_PEACE
    elif [[ "$locationLower" == *"raklion"* && "$locationLower" == *"3"* ]]; then
        echo $LOC_RAKLION_3
    elif [[ "$locationLower" == *"tuary"* ]]; then
        echo $LOC_SANCTUARY
    elif [[ "$locationLower" == *"orrupt"* && "$locationLower" == *"land"* ]]; then
        echo $LOC_CORRUPTED_LANDS
    elif [[ "$locationLower" == *"divine"* ]]; then
        echo $LOC_DIVINE_REALM
    elif [[ "$locationLower" == *"land"* && "$locationLower" == *"demon"* ]]; then
        echo $LOC_LAND_OF_DEMONS
    elif [[ "$locationLower" == *"fog"* ]]; then
        echo $LOC_FOGGY_FOREST
    elif [[ "$locationLower" == *"eversong"* ]]; then
        echo $LOC_EVERSONG_FOREST
    elif [[ "$locationLower" == *"devil"* && "$locationLower" == *"square"* ]]; then
        echo $LOC_DEVIL_SQUARE
    elif [[ "$locationLower" == *"blood"* && "$locationLower" == *"cast"* ]]; then
        echo $LOC_BLOOD_CASTLE
    elif [[ "$locationLower" == *"abby"* || "$locationLower" == *"fer"* ]]; then
        echo $LOC_ABYSSAL_FEREA
    else
        echo $LOC_UNKNOWN
    fi

    return 0
}


# Function to compare a screen region with a reference image
# Parameters: X Y WIDTH HEIGHT REFERENCE_IMAGE_PATH
# Returns: "similar" if similarity > 80%, "not_similar" otherwise
# Exit code: 0 if similar, 1 if not similar
compareScreenRegionWithImage() {
    local X=$1
    local Y=$2
    local WIDTH=$3
    local HEIGHT=$4
    local REFERENCE_IMAGE=$5

    # Local debug flag - set to true to save cropped images to Desktop
    local DEBUG_SAVE_IMAGE=false

    # Similarity threshold (0-100%)
    local SIMILARITY_THRESHOLD=80

    # Validate parameters
    if [[ -z "$X" || -z "$Y" || -z "$WIDTH" || -z "$HEIGHT" || -z "$REFERENCE_IMAGE" ]]; then
        echo "Error: Missing parameters. Usage: compareScreenWithImage X Y WIDTH HEIGHT REFERENCE_IMAGE_PATH" >&2
        return 1
    fi

    # Validate reference image exists
    if [[ ! -f "$REFERENCE_IMAGE" ]]; then
        echo "Error: Reference image not found: $REFERENCE_IMAGE" >&2
        return 1
    fi

    # Setup temp file path only if debugging
    local TEMP_FILE=""
    if [ "$DEBUG_SAVE_IMAGE" = true ]; then
        local DESKTOP_DIR="$HOME/Desktop"
        TEMP_FILE="${DESKTOP_DIR}/compare_crop_${X}_${Y}.png"
    fi

    # Get comparison script path
    local COMPARE_SCRIPT="$PROJECT_DIR/python/compareImages.py"

    # Capture screenshot, crop, and compare with reference image
    local SIMILARITY_PERCENT

    if [ "$DEBUG_SAVE_IMAGE" = true ]; then
        # DEBUG MODE: Save to disk AND pipe to Python
        SIMILARITY_PERCENT=$(adb_screencap | \
            magick png:- -crop ${WIDTH}x${HEIGHT}+${X}+${Y} \
            png:- | \
            tee "$TEMP_FILE" | \
            python3 "$COMPARE_SCRIPT" "$REFERENCE_IMAGE" --stdin 2>/dev/null)

        echo "[DEBUG] Saved comparison crop to: $TEMP_FILE" >&2
        echo "[DEBUG] Similarity: ${SIMILARITY_PERCENT}%" >&2
    else
        # NORMAL MODE: Everything in memory (no SSD writes)
        SIMILARITY_PERCENT=$(adb_screencap | \
            magick png:- -crop ${WIDTH}x${HEIGHT}+${X}+${Y} \
            png:- | \
            python3 "$COMPARE_SCRIPT" "$REFERENCE_IMAGE" --stdin 2>/dev/null)
    fi

    # Check if we got a valid similarity value
    if [[ -z "$SIMILARITY_PERCENT" ]]; then
        echo "not_similar"
        return 1
    fi

    # Compare with threshold
    # Use bc for floating point comparison
    if (( $(echo "$SIMILARITY_PERCENT >= $SIMILARITY_THRESHOLD" | bc -l) )); then
        echo "similar"
        return 0
    else
        echo "not_similar"
        return 1
    fi
}

exportCroppedImage() {
    local X=$1
    local Y=$2
    local WIDTH=$3
    local HEIGHT=$4

    # Validate parameters
    if [[ -z "$X" || -z "$Y" || -z "$WIDTH" || -z "$HEIGHT" ]]; then
        echo "Error: Missing parameters. Usage: exportCroppedImage X Y WIDTH HEIGHT" >&2
        return 1
    fi

    # Setup file path on Desktop
    local DESKTOP_DIR="$HOME/Desktop"
    local TEMP_FILE="${DESKTOP_DIR}/exported_crop_${X}_${Y}.png"

    # Capture screenshot and crop to file
    adb_screencap | \
        magick png:- -crop ${WIDTH}x${HEIGHT}+${X}+${Y} \
        "$TEMP_FILE"

    # Check if file was created successfully
    if [[ -f "$TEMP_FILE" ]]; then
        echo "Exported cropped image to: $TEMP_FILE" >&2
        return 0
    else
        echo "Error: Failed to export cropped image" >&2
        return 1
    fi
}


# Function to check if game is running and in foreground
# Returns: 0 if game is in foreground, 1 if closed or in background
isGameRunning() {
    local packageName="$GAME_PACKAGE"

    # Step 1: Check if the app process is running (using adb_shell wrapper for device selection)
    local pid=$(adb_shell pidof "$packageName" 2>/dev/null | tr -d '\r')
    if [[ -z "$pid" || ! "$pid" =~ ^[0-9]+$ ]]; then
        echo "[$(date '+%H:%M:%S')] Game process not running" >&2
        return 1  # App is not running
    fi

    # Step 2: Check if the app is in the foreground
    local currentActivity=$(adb_shell dumpsys activity activities 2>/dev/null | grep -E 'topResumedActivity|mResumedActivity' | head -1)
    if [[ "$currentActivity" == *"$packageName"* ]]; then
        return 0  # Game is in foreground
    else
        echo "[$(date '+%H:%M:%S')] Game is running but not in foreground" >&2
        return 1  # Game is in background
    fi
}

isLoggedIn() {
    # Reference image path
    local LOGOUT_MARKER_IMAGE="$PROJECT_DIR/img/logout_marker.png"

    # Zone coordinates to check for logout marker
    local X=731 # Migrated
    local Y=207 # Migrated
    local WIDTH=285 # Migrated
    local HEIGHT=100 # Migrated

    # Check if logout marker is present
    local result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$LOGOUT_MARKER_IMAGE")

    if [[ "$result" == "similar" ]]; then
        # Logout marker found = user is not logged in
        return 1
    else
        # Logout marker not found = user is logged in
        return 0
    fi
}

isCharacterSelected() {
    # Reference image path
    local LOGOUT_MARKER_IMAGE="$PROJECT_DIR/img/character_selection_marker.png"

    # Zone coordinates to check for character selection marker
    local X=805 # Migrated
    local Y=230 # Migrated
    local WIDTH=305 # Migrated
    local HEIGHT=75 # Migrated

    # Check if logout marker is present
    local result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$LOGOUT_MARKER_IMAGE")

    if [[ "$result" == "similar" ]]; then
        # Character selection marker found = character not selected
        return 1
    else
        # Character selection marker not found = character is selected
        return 0
    fi
}

# Function to check if event has ended by looking for "Event is over" screen
# Returns: 0 if event is over, 1 if not
isEventOver() {
    local MARKER_IMAGE="$PROJECT_DIR/img/event_is_over_marker.png"

    local X=595 # Migrated
    local Y=166 # Migrated
    local WIDTH=730 # Migrated
    local HEIGHT=58 # Migrated

    local result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$MARKER_IMAGE")

    if [[ "$result" == "similar" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if "Open now" button is present (event is ready to start)
# Returns: 0 if Open now button detected, 1 if not
# Function to check if expired popup is visible (e.g. "Jewel Boost Card has expired")
# Detects the "Go recharge" button at position 1585,865
# Returns: 0 if popup is visible, 1 if not
isExpiredPopupVisible() {
    local MARKER_IMAGE="$PROJECT_DIR/img/expired_popup_marker.png"

    local X=1030
    local Y=700
    local WIDTH=150
    local HEIGHT=28

    local result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$MARKER_IMAGE")

    if [[ "$result" == "similar" ]]; then
        return 0
    else
        return 1
    fi
}

isOpenNowButtonVisible() {
    local MARKER_IMAGE="$PROJECT_DIR/img/open_now_button_marker.png"

    local X=177
    local Y=305
    local WIDTH=110
    local HEIGHT=23

    local result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$MARKER_IMAGE")

    if [[ "$result" == "similar" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if recycle reminder popup is visible
# Detects the red "Recycle" button at the bottom-left of the popup
# Returns: 0 if popup is visible, 1 if not
isRecyclePopupVisible() {
    local MARKER_IMAGE="$PROJECT_DIR/img/recycle_popup_marker.png"

    local X=775 # Migrated
    local Y=620 # Migrated
    local WIDTH=98 # Migrated
    local HEIGHT=37 # Migrated

    local result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$MARKER_IMAGE")

    if [[ "$result" == "similar" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to find and tap a daily goal event by comparing icons in the grid
# The Daily Goal window has a 2-column x 4-row grid of events
# Parameters: $1 = Daily Goal constant (DG_KUNDUN_TRIAL, DG_BLOOD_CASTLE, etc.)
# Returns: 0 if found and tapped, 1 if not found
findAndTapDailyGoalEvent() {
    local eventId=$1

    if [[ -z "$eventId" ]]; then
        echo "Error: Missing event. Usage: findAndTapDailyGoalEvent DG_EVENT" >&2
        return 1
    fi

    # Map event constant to marker image file
    local markerImage=""
    case $eventId in
        $DG_MYSTICLAND_BOSS) markerImage="mysticland_boss.png" ;;
        $DG_BLOOD_CASTLE)    markerImage="blood_castle.png" ;;
        $DG_COURAGE_TRIAL)   markerImage="courage_trial.png" ;;
        $DG_KUNDUN_TRIAL)    markerImage="kundun_trial.png" ;;
        $DG_GOLDEN_MONSTER)  markerImage="golden_monster.png" ;;
        $DG_FIELD_BOSS)      markerImage="field_boss.png" ;;
        $DG_DEVIL_SQUARE)    markerImage="devil_square.png" ;;
        $DG_WARRIOR_QUEST)   markerImage="warrior_quest.png" ;;
        *)
            echo "Error: Unknown daily goal event '$eventId'" >&2
            return 1
            ;;
    esac

    local MARKER_PATH="$PROJECT_DIR/img/daily_goal/$markerImage"
    if [[ ! -f "$MARKER_PATH" ]]; then
        echo "Error: Marker image not found: $MARKER_PATH" >&2
        return 1
    fi

    # Grid icon positions: 2 columns x 4 rows
    # Icon size: 118x118
    local ICON_SIZE=118
    local ICON_X_COL0=260
    local ICON_X_COL1=834
    local ICON_Y_ROW0=260
    local ICON_Y_ROW1=406
    local ICON_Y_ROW2=552
    local ICON_Y_ROW3=698

    # Tap centers for each cell
    local TAP_X_COL0=730
    local TAP_X_COL1=1300
    local TAP_Y_ROW0=325
    local TAP_Y_ROW1=475
    local TAP_Y_ROW2=625
    local TAP_Y_ROW3=775

    # Check each cell: (col0,row0) (col1,row0) (col0,row1) ... (col1,row3)
    local iconXList="$ICON_X_COL0 $ICON_X_COL1 $ICON_X_COL0 $ICON_X_COL1 $ICON_X_COL0 $ICON_X_COL1 $ICON_X_COL0 $ICON_X_COL1"
    local iconYList="$ICON_Y_ROW0 $ICON_Y_ROW0 $ICON_Y_ROW1 $ICON_Y_ROW1 $ICON_Y_ROW2 $ICON_Y_ROW2 $ICON_Y_ROW3 $ICON_Y_ROW3"
    local tapXList="$TAP_X_COL0 $TAP_X_COL1 $TAP_X_COL0 $TAP_X_COL1 $TAP_X_COL0 $TAP_X_COL1 $TAP_X_COL0 $TAP_X_COL1"
    local tapYList="$TAP_Y_ROW0 $TAP_Y_ROW0 $TAP_Y_ROW1 $TAP_Y_ROW1 $TAP_Y_ROW2 $TAP_Y_ROW2 $TAP_Y_ROW3 $TAP_Y_ROW3"

    local cell=0
    while [ $cell -lt 8 ]; do
        local ix=$(echo $iconXList | cut -d' ' -f$((cell+1)))
        local iy=$(echo $iconYList | cut -d' ' -f$((cell+1)))
        local tx=$(echo $tapXList | cut -d' ' -f$((cell+1)))
        local ty=$(echo $tapYList | cut -d' ' -f$((cell+1)))

        local result=$(compareScreenRegionWithImage $ix $iy $ICON_SIZE $ICON_SIZE "$MARKER_PATH")
        if [[ "$result" == "similar" ]]; then
            echo "[Daily Goal] Found event in cell $cell, tapping ($tx, $ty)" >&2
            adb_tap $tx $ty
            return 0
        fi
        cell=$((cell + 1))
    done

    echo "[Daily Goal] Event not found in any cell" >&2
    return 1
}
