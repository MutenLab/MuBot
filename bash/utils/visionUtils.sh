#!/bin/bash

# Guard against multiple sourcing
if [ -n "$_VISION_UTILS_LOADED" ]; then
    return 0 2>/dev/null || true
fi
_VISION_UTILS_LOADED=1

# Load configuration for device targeting
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

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
readonly LOC_SANCTUARY_1=13
readonly LOC_CORRUPTED_LANDS=14
readonly LOC_LAND_OF_DEMONS=15
readonly LOC_SANCTUARY_2=16
readonly LOC_FOGGY_FOREST=17
readonly LOC_SANCTUARY_3=21
readonly LOC_SANCTUARY_4=22
readonly LOC_SANCTUARY_5=23
readonly LOC_SANCTUARY_6=24
readonly LOC_EVERSONG_FOREST=18
readonly LOC_DEVIL_SQUARE=19
readonly LOC_BLOOD_CASTLE=20

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
    local OCR_SCRIPT="/Users/icerrate/AndroidStudioProjects/bot/python/readNumbersOCR.py"

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
    local OCR_SCRIPT="/Users/icerrate/AndroidStudioProjects/bot/python/readTextOCR.py"

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
# Returns: remaining time in seconds, or -1 if unable to read
# Exit code: 0 if time read successfully, 1 if failed
checkRemainTimeForEventToEnd() {
    local X=718
    local Y=450
    local WIDTH=120
    local HEIGHT=40

    # Get OCR script path
    local OCR_SCRIPT="/Users/icerrate/AndroidStudioProjects/bot/python/readTextOCR.py"

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
    local OCR_SCRIPT="/Users/icerrate/AndroidStudioProjects/bot/python/readTextOCR.py"

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
    elif [[ "$locationLower" == *"tuary"* && "$locationLower" == *"1"* ]]; then
        echo $LOC_SANCTUARY_1
    elif [[ "$locationLower" == *"tuary"* && "$locationLower" == *"2"* ]]; then
        echo $LOC_SANCTUARY_2
    elif [[ "$locationLower" == *"tuary"* && "$locationLower" == *"3"* ]]; then
        echo $LOC_SANCTUARY_3
    elif [[ "$locationLower" == *"tuary"* && "$locationLower" == *"4"* ]]; then
        echo $LOC_SANCTUARY_4
    elif [[ "$locationLower" == *"tuary"* && "$locationLower" == *"5"* ]]; then
        echo $LOC_SANCTUARY_5
    elif [[ "$locationLower" == *"tuary"* && "$locationLower" == *"6"* ]]; then
        echo $LOC_SANCTUARY_6
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
    local COMPARE_SCRIPT="/Users/icerrate/AndroidStudioProjects/bot/python/compareImages.py"

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
    local LOGOUT_MARKER_IMAGE="/Users/icerrate/AndroidStudioProjects/bot/img/logout_marker.png"

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
    local LOGOUT_MARKER_IMAGE="/Users/icerrate/AndroidStudioProjects/bot/img/character_selection_marker.png"

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
    local MARKER_IMAGE="/Users/icerrate/AndroidStudioProjects/bot/img/event_is_over_marker.png"

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
    local MARKER_IMAGE="/Users/icerrate/AndroidStudioProjects/bot/img/expired_popup_marker.png"

    local X=1585
    local Y=865
    local WIDTH=190
    local HEIGHT=42

    local result=$(compareScreenRegionWithImage "$X" "$Y" "$WIDTH" "$HEIGHT" "$MARKER_IMAGE")

    if [[ "$result" == "similar" ]]; then
        return 0
    else
        return 1
    fi
}

isOpenNowButtonVisible() {
    local MARKER_IMAGE="/Users/icerrate/AndroidStudioProjects/bot/img/open_now_button_marker.png"

    local X=371
    local Y=381
    local WIDTH=140
    local HEIGHT=29

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
    local MARKER_IMAGE="/Users/icerrate/AndroidStudioProjects/bot/img/recycle_popup_marker.png"

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
