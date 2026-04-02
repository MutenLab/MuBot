#!/bin/bash

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

# Game package is defined in variables.sh as GAME_PACKAGE

echo "[$(date '+%H:%M:%S')] Starting game app..."

# Start the game using monkey (simulates launcher tap - works with non-exported activities)
adb_shell monkey -p "$GAME_PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

# Dismiss startup add popup
sleep 5
tap_startup_close_ads

# Wait for game to load
sleep 55
# Click Start Game at login
tap_login_start_game
sleep 15
# Click Start Game at character selection
tap_character_selection_start_game
sleep 20
# Click close auto-play pop up
tap_close_auto_play_pop_up
sleep 1
# Click close expired pop up
tap_close_expired_pop_up
sleep 1
tap_close_expired_pop_up
sleep 1
