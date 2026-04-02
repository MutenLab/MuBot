#!/bin/bash

# Load configuration
source /Users/icerrate/AndroidStudioProjects/bot/config/variables.sh

sleep 1
# Press back to show close dialog
adb_key 4
# Click confirm close
sleep 1
tap_exit_game_confirm
