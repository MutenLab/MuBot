#!/bin/bash

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

sleep 1
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
