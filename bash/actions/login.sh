#!/bin/bash

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

sleep 1
# Click Start Game at login
tap_login_start_game
sleep 10
# Click on confirm update if popup is showed
tap_update_confirm
sleep 60 # 20 if no update. Otherwise 60
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
